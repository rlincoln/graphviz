#include <stdlib.h>
#include <string.h>

#include "ppapi/c/ppp.h"
#include "ppapi/c/ppp_messaging.h"

#include "ppapi_common.h"

void Messaging_HandleMessage(PP_Instance instance, struct PP_Var var_message) {
	struct PP_Var var_id;
	struct PP_Var var_payload;
	if (ParsePayloadMessage(var_message, &var_id, &var_payload)) {
		var_payload = var_message;  // not an id/payload message
	}

	const char* function_name;
	struct PP_Var var_params;
	if (ParseCommandMessage(var_payload, &function_name, &var_params)) {
		PostIdMessage(var_id, var_payload); 
		return;
	}

	if (strcmp(function_name, "echo") != 0) {
		PostStringMessage("error: unrecognized command: \"%s\"", function_name);
	}

	if (PostIdMessage(var_id, var_params)) {
		PostStringMessage("error: unable to post id message");
	}
	g_ppb_var->Release(var_id);
}


/*
void (*msg_handler(FuncNameMapping function_map[]))(PP_Instance instance, struct PP_Var message) {
	g_function_map = function_map;
	return Messaging_HandleMessage;
}

static FuncNameMapping echo_function_map[] = {
	{ NULL, NULL }
};
*/

typedef struct {
	char* name;
	HandleFunc function;
} FuncNameMapping;

#define MAX_FUNC_MAPPING 50

static FuncNameMapping g_function_map[MAX_FUNC_MAPPING];
/*static unsigned int _num_reg = 0;

static int PPAPICommon_RegisterHandler(const char* name, HandleFunc function) {
	if (_num_reg > MAX_FUNC_MAPPING) {
		return 1;
	}
	strcpy(g_function_map[_num_reg].name, name);
	g_function_map[_num_reg].function = function;
	_num_reg++;
	return 0;
}
*/

/**
 * Given a function name, look up its handler function.
 * @param[in] function_name The function name to look up.
 * @return The handler function mapped to |function_name|.
 */
static HandleFunc GetFunctionByName(const char* function_name) {
	FuncNameMapping* map_iter = g_function_map;
	for (; map_iter->name; ++map_iter) {
		if (strcmp(map_iter->name, function_name) == 0) {
			return map_iter->function;
		}
	}

	return NULL;
}

void PPAPICommon_HandleCommandMessage(PP_Instance instance, struct PP_Var var_message) {
	PostStringMessage("error");
	return;

	struct PP_Var var_id = PP_MakeUndefined();
	/*struct PP_Var var_payload;
	if (ParsePayloadMessage(var_message, &var_id, &var_payload)) {
		var_payload = var_message;  // not an id/payload message
	}*/

	const char* function_name;
	struct PP_Var var_params;
	if (ParseCommandMessage(var_message, &function_name, &var_params)) {
		PostStringMessage("Error: Unable to parse message");
		return;
	}

	HandleFunc function = GetFunctionByName(function_name);
	if (!function) {
		PostStringMessage("Error: Unknown function \"%s\"", function_name);
		return;
	}

	
	struct PP_Var var_result;
	const char* error;
	int result = (*function)(var_params, &var_result, &error);
	if (result != 0) {
		if (error != NULL) {
			PostStringMessage("Error: \"%s\" failed: %s.", function_name, error);
			free((void*) error);
		} else {
			PostStringMessage("Error: \"%s\" failed.", function_name);
		}
		return;
	}
	
	if (PostIdMessage(var_id, var_result)) {
		PostStringMessage("error: unable to post id message");
	}
	g_ppb_var->Release(var_id);
	g_ppb_var->Release(var_result);
}

int HandleEcho(struct PP_Var params, struct PP_Var* output, const char** out_error) {
    *out_error = PrintfToNewString("unsuccessful");
	return 1;
//	*output = params;
//	return 0;
}


PP_EXPORT const void* PPP_GetInterface(const char* interface_name) {
	if (strcmp(interface_name, PPP_INSTANCE_INTERFACE) == 0) {
		return &g_instance_interface;
	}
/*
	if (strcmp(interface_name, PPP_MESSAGING_INTERFACE) == 0) {
		static PPP_Messaging messaging_interface = {
			&Messaging_HandleMessage
//			&PPAPICommon_HandleCommandMessage
		};
		return &messaging_interface;
	}*/
	return NULL;
}
/*
PP_EXPORT int32_t PPP_InitializeModule(PP_Module a_module_id,
		PPB_GetInterface get_browser) {

	PPAPICommon_RegisterHandler("echo", HandleEcho);	

	return PPAPICommon_InitializeModule(a_module_id, get_browser);
}*/

PP_EXPORT int32_t PPP_InitializeModule(PP_Module a_module_id, PPB_GetInterface get_browser) {
	g_get_browser_interface = get_browser;
	GET_INTERFACE(g_ppb_instance, PPB_Instance, PPB_INSTANCE_INTERFACE);
	GET_INTERFACE(g_ppb_messaging, PPB_Messaging, PPB_MESSAGING_INTERFACE);
	GET_INTERFACE(g_ppb_var, PPB_Var, PPB_VAR_INTERFACE);
	GET_INTERFACE(g_ppb_var_array, PPB_VarArray, PPB_VAR_ARRAY_INTERFACE);
	GET_INTERFACE(g_ppb_var_dictionary, PPB_VarDictionary,
			PPB_VAR_DICTIONARY_INTERFACE);
	GET_INTERFACE(g_ppb_var_array_buffer, PPB_VarArrayBuffer,
			PPB_VAR_ARRAY_BUFFER_INTERFACE);
	return PP_OK;
}

PP_EXPORT void PPP_ShutdownModule() {
}

