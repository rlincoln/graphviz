#include <stdlib.h>
#include <string.h>

#include "ppapi/c/ppp.h"
#include "ppapi/c/ppp_messaging.h"

#include "ppapi_common.h"

int HandleDot(struct PP_Var params, struct PP_Var* out, const char** error) {
    return 0;
}

PP_EXPORT const void* PPP_GetInterface(const char* interface_name) {
    if (strcmp(interface_name, PPP_INSTANCE_INTERFACE) == 0) {
        return &g_instance_interface;
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
