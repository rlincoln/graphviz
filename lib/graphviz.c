#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>

#include <unistd.h>
#include <fcntl.h>

#include <sys/mount.h>

#include "ppapi/c/ppp.h"
#include "ppapi/c/ppp_messaging.h"

#include "ppapi_common.h"

#include "gvc.h"
#include "gvplugin.h"

#include "nacl_io/ioctl.h"
#include "nacl_io/nacl_io.h"

#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y))

static GVC_t *Gvc;
static graph_t * G;

extern gvplugin_library_t gvplugin_core_LTX_library;
extern gvplugin_library_t gvplugin_dot_layout_LTX_library;
extern gvplugin_library_t gvplugin_neato_layout_LTX_library;

lt_symlist_t lt_preloaded_symbols[] = {
	{ "gvplugin_dot_layout_LTX_library",
		(void*)(&gvplugin_dot_layout_LTX_library) },
//	{ "gvplugin_neato_layout_LTX_library",
//		(void*)(&gvplugin_neato_layout_LTX_library) },
	{ "gvplugin_core_LTX_library",
		(void*)(&gvplugin_core_LTX_library) },
	{ NULL, NULL }
};

char* read_all_file(char* fname) {
	char* buffer = 0;
	long length;
	FILE* f = fopen(fname, "rb");

	if (f) {
		fseek(f, 0, SEEK_END);
		length = ftell(f);
		fseek(f, 0, SEEK_SET);
		buffer = malloc(length);
		if (buffer) {
			if (fread(buffer, 1, length, f) != length) {
				return 0;
			}
		}
		fclose(f);
	}
	return buffer;
}

int HandleDot(struct PP_Var params, struct PP_Var* output,
		const char** out_error) {
	CHECK_PARAM_COUNT(dot, 4);
	PARAM_STRING(0, dotdata);
	PARAM_STRING(1, output_format);
	PARAM_STRING(2, layout_engine);
	PARAM_INT(3, verbose);

//	fprintf(stderr, "dotdata: %s", dotdata);

	graph_t *prev = NULL;

	int rr;
	int rc = 0;
	const int K = 32;

//	char *output_format = "xdot";
//	char *layout_engine = "dot";
//	int verbose = 1;

	// Generate file names.
	int irand = rand();
	char infile[K], outfile[K], stdoutfile[K], stderrfile[K];
	sprintf(infile, "/gv/%d.in", irand);
	sprintf(outfile, "/gv/%d.out", irand);
	sprintf(stdoutfile, "/gv/%d.stdout", irand);
	sprintf(stderrfile, "/gv/%d.stderr", irand);

	// Write the message content to the input file.
	FILE *fp_in = fopen(infile, "w");
	if (fp_in == NULL) {
		*out_error = PrintfToNewString("fopen %s", infile);
		return 1;
	}
	fprintf(fp_in, "%s", dotdata);
	fclose(fp_in);

	//FILE *r = freopen("/gv/in", "r", stdin);
	//if (!r) {}

/*
	fp_in = fopen("/gv/in", "rw");
	if (fp_in != NULL) {
		dup2(fileno(fp_in), 0);
		fclose(fp_in);
	}

	fp_in = fopen("/gv/out", "w");
	if (fp_in != NULL) {
		fprintf(fp_in, "%s", message);
		fclose(fp_in);
	}
*/

	// Build the argument list.
	/*char formatflag[K], layoutflag[K], outflag[K];
	sprintf(formatflag, "-T%s", output_format);
	sprintf(layoutflag, "-K%s", layout_engine);
	sprintf(outflag, "-o%s", outfile);
	int argc = verbose ? 6 : 5;
	char** argv = calloc(sizeof(char*), argc);
	argv[0] = "dot";
	argv[1] = formatflag;
	argv[2] = layoutflag;
	argv[3] = outflag;
	argv[4] = infile;
	if (verbose) {
		argv[5] = "-v";
	}*/

	char formatflag[K], layoutflag[K];
	sprintf(formatflag, "-T%s", output_format);
	sprintf(layoutflag, "-K%s", layout_engine);
	int argc = verbose ? 5 : 4;
	char** argv = calloc(sizeof(char*), argc);
	argv[0] = "dot";
	argv[1] = formatflag;
	argv[2] = layoutflag;
	argv[3] = infile;
	if (verbose) {
		argv[4] = "-v";
	}

/*
	int argc = 4;
	char** argv = calloc(sizeof(char*), argc);
	argv[0] = "dot";
	argv[1] = "-Tdot";
	argv[2] = "-Kdot";
	argv[3] = "-v";
*/

	// Redirect stdout and stderr to file.
	int out = open(stdoutfile, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == out) {
		*out_error = PrintfToNewString("open stdout file (%d)", out);
		return 1;
	}

	int err = open(stderrfile, O_RDWR|O_CREAT|O_APPEND, 0600);
	if (-1 == err) {
		*out_error = PrintfToNewString("open stderr file (%d)", err);
		return 1;
	}

	int save_out = dup(fileno(stdout));
	int save_err = dup(fileno(stderr));

	if (-1 == dup2(out, fileno(stdout))) {
		*out_error = PrintfToNewString("redirect stdout");
		return 1;
	}
	if (-1 == dup2(err, fileno(stderr))) {
		*out_error = PrintfToNewString("redirect stderr");
		return 1;
	}

	// Build and perform layout and render jobs.
	Gvc = gvContextPlugins(lt_preloaded_symbols, 0);
	//GvExitOnUsage = 0;
	gvParseArgs(Gvc, argc, argv);

	if ((G = gvPluginsGraph(Gvc))) {
		gvLayoutJobs(Gvc, G);
		gvRenderJobs(Gvc, G);
	} else {
		while ((G = gvNextInputGraph(Gvc))) {
			if (prev) {
				gvFreeLayout(Gvc, prev);
				agclose(prev);
			}
			gvLayoutJobs(Gvc, G);
			gvRenderJobs(Gvc, G);
			rr = agreseterrors();
			rc = MAX(rc,rr);
			prev = G;
		}
	}

	gvFinalize(Gvc);
	rr = gvFreeContext(Gvc);


	// Undo redirection of stdout and stderr.
	fflush(stdout); close(out);
	fflush(stderr); close(err);

	dup2(save_out, fileno(stdout));
	dup2(save_err, fileno(stderr));

	close(save_out);
	close(save_err);

	if (MAX(rc,rr) != 0) {
		*out_error = PrintfToNewString("rc: %d rr: %d", rc, rr);
		return 1;
		/*PP_Bool result;

		struct PP_Var dict_var = g_ppb_var_dictionary->Create();
		struct PP_Var key_var = CStrToVar(key);
		struct PP_Var value_var = CStrToVar(val);

		result = PSInterfaceVarDictionary()->Set(dict_var, key_var, value_var);
		PSInterfaceVar()->Release(key_var);
		PSInterfaceVar()->Release(value_var);

		if (!result) {
			PSInterfaceVar()->Release(dict_var);
			*out_error = PrintfToNewString("Unable to set \"%s\" key in result dictionary", key);
			return;
		}*/
	}


	// Create a message with the content of the output file.
	/*char* buffer = 0;
	long length;
	FILE* f = fopen(outfile, "rb");

	if (f) {
		fseek(f, 0, SEEK_END);
		length = ftell(f);
		fseek(f, 0, SEEK_SET);
		buffer = malloc(length);
		if (buffer) {
			if (fread(buffer, 1, length, f) != length) {
				*out_error = PrintfToNewString("fread stdout");
				return 1;
			}
		}
		fclose(f);
	}*/

	char* outfile_buffer = read_all_file(outfile);
	if (outfile_buffer != 0) {
		fprintf(stderr, "outfile: %s", outfile_buffer);
	}
	char* stdoutfile_buffer = read_all_file(stdoutfile);
	if (stdoutfile_buffer != 0) {
		fprintf(stderr, "stdoutfile: %s", stdoutfile_buffer);
	}
	char* stderrfile_buffer = read_all_file(stderrfile);
	if (stderrfile_buffer != 0) {
		fprintf(stderr, "stderrfile: %s", stderrfile_buffer);
	}

	remove(infile);
	remove(outfile);
	remove(stdoutfile);
	remove(stderrfile);

//	free(message);

	CREATE_RESPONSE(dot);
//	RESPONSE_STRING(outfile_buffer);
	RESPONSE_STRING(stdoutfile_buffer);
	RESPONSE_STRING(stderrfile_buffer);
	return 0;
}

static PP_Bool Instance_DidCreate(PP_Instance instance, uint32_t argc,
		const char* argn[], const char* argv[]) {
	g_instance = instance;

	srand(time(NULL));

	nacl_io_init_ppapi(instance, g_get_browser_interface);
	mount("", "/gv", "memfs", 0, "");

	int fd1 = open("/dev/console1", O_WRONLY);
	dup2(fd1, 1);

	int fd2 = open("/dev/console1", O_WRONLY);
	dup2(fd2, 2);

	return PP_TRUE;
}

PP_EXPORT const void* PPP_GetInterface(const char* interface_name) {
	if (strcmp(interface_name, PPP_INSTANCE_INTERFACE) == 0) {
		static PPP_Instance instance_interface = {
			&Instance_DidCreate,
			&PPAPICommon_Instance_DidDestroy,
			&PPAPICommon_Instance_DidChangeView,
			&PPAPICommon_Instance_DidChangeFocus,
			&PPAPICommon_Instance_HandleDocumentLoad
		};
		return &instance_interface;
		//g_instance_interface.DidCreate = &Instance_DidCreate;
		//return &g_instance_interface;
	}

	if (strcmp(interface_name, PPP_MESSAGING_INTERFACE) == 0) {
		static PPP_Messaging messaging_interface = {
			&PPAPICommon_HandleCommandMessage
		};
		return &messaging_interface;
	}
	return NULL;
}

PP_EXPORT int32_t PPP_InitializeModule(PP_Module a_module_id,
		PPB_GetInterface get_browser) {
	PPAPICommon_RegisterHandler("dot", HandleDot);
	return PPAPICommon_InitializeModule(a_module_id, get_browser);
}

PP_EXPORT void PPP_ShutdownModule() {
}
