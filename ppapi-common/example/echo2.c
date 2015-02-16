#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "ppapi/c/pp_errors.h"
#include "ppapi/c/pp_module.h"
#include "ppapi/c/pp_var.h"
#include "ppapi/c/ppb.h"
#include "ppapi/c/ppb_instance.h"
#include "ppapi/c/ppb_messaging.h"
#include "ppapi/c/ppb_var.h"
#include "ppapi/c/ppp.h"
#include "ppapi/c/ppp_instance.h"
#include "ppapi/c/ppp_messaging.h"
#include "ppapi/c/ppb_var_array.h"
#include "ppapi/c/ppb_var_array_buffer.h"
#include "ppapi/c/ppb_var_dictionary.h"

//#include "ppapi/c/ppp.h"
//#include "ppapi/c/ppp_messaging.h"

//#include "ppapi_common.h"

static PPB_Var* g_ppb_var = NULL;
static PPB_Messaging* g_ppb_messaging = NULL;
static PPB_Instance* g_ppb_instance = NULL;
static PPB_VarArray* g_ppb_var_array = NULL;
static PPB_VarDictionary* g_ppb_var_dictionary = NULL;
static PPB_VarArrayBuffer* g_ppb_var_array_buffer = NULL;

static PP_Instance g_instance = 0;
static PPB_GetInterface g_get_browser_interface = NULL;

static PP_Bool Instance_DidCreate(PP_Instance instance, uint32_t argc,
        const char* argn[], const char* argv[]) {
    g_instance = instance;
    return PP_TRUE;
}

static void Instance_DidDestroy(PP_Instance instance) {
}

static void Instance_DidChangeView(PP_Instance instance, PP_Resource view) {
}

static void Instance_DidChangeFocus(PP_Instance instance, PP_Bool has_focus) {
}

static PP_Bool Instance_HandleDocumentLoad(PP_Instance instance, PP_Resource url_loader) {
    return PP_FALSE;
}

void Messaging_HandleMessage(PP_Instance instance, struct PP_Var var_message) {
	//g_ppb_messaging->PostMessage(g_instance, var_message);
}

PP_EXPORT const void* PPP_GetInterface(const char* interface_name) {
	if (strcmp(interface_name, PPP_INSTANCE_INTERFACE) == 0) {
        static PPP_Instance instance_interface = {
                &Instance_DidCreate,
                &Instance_DidDestroy,
                &Instance_DidChangeView,
                &Instance_DidChangeFocus,
                &Instance_HandleDocumentLoad
        };
        return &instance_interface;
	}
	if (strcmp(interface_name, PPP_MESSAGING_INTERFACE) == 0) {
		static PPP_Messaging messaging_interface = {
			&Messaging_HandleMessage
		};
		return &messaging_interface;
	}
	return NULL;
}

#define GET_INTERFACE(var, type, name)            \
  var = (type*)(get_browser(name));               \
  if (!var) {                                     \
    printf("Unable to get interface " name "\n"); \
    return PP_ERROR_FAILED;                       \
  }

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

