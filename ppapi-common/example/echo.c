
#include <string.h>

#include "ppapi/c/ppp.h"
#include "ppapi/c/ppp_messaging.h"

#include "ppapi_common.h"

void Messaging_HandleMessage(PP_Instance instance, struct PP_Var var_message) {
	/*const char* function_name;
	struct PP_Var params;
	if (ParseMessage(var_message, &function_name, &params)) {
		PostMessage("Error: Unable to parse message");
		return;
	}*/

	g_ppb_messaging->PostMessage(g_instance, var_message);
//	g_ppb_var->Release(result_var);
}

PP_EXPORT const void* PPP_GetInterface(const char* interface_name) {
	if (strcmp(interface_name, PPP_INSTANCE_INTERFACE) == 0) {
		return &g_instance_interface;
	}

	if (strcmp(interface_name, PPP_MESSAGING_INTERFACE) == 0) {
		static PPP_Messaging messaging_interface = {
			&Messaging_HandleMessage
		};
		return &messaging_interface;
	}
	return NULL;
}

PP_EXPORT int32_t PPP_InitializeModule(PP_Module a_module_id,
		PPB_GetInterface get_browser) {
	return PPAPICommon_InitializeModule(a_module_id, get_browser);
}

PP_EXPORT void PPP_ShutdownModule() {
}

