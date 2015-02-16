/* Copyright (c) 2012 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. */

#ifndef NACL_MODULE_H_
#define NACL_MODULE_H_

#include <stdarg.h>
#include "ppapi/c/pp_var.h"
#include "ppapi/c/ppb.h"

#include "ppapi/c/pp_errors.h"
#include "ppapi/c/ppp_instance.h"

#include "ppapi/c/ppb_var.h"
#include "ppapi/c/ppb_instance.h"
#include "ppapi/c/ppb_messaging.h"
#include "ppapi/c/ppb_var_array.h"
#include "ppapi/c/ppb_var_array_buffer.h"
#include "ppapi/c/ppb_var_dictionary.h"
#include "sdk_util/macros.h"  // for PRINTF_LIKE


/*
static PP_Bool PPAPICommon_Instance_DidCreate(PP_Instance instance,
		uint32_t argc, const char* argn[], const char* argv[]);
static void PPAPICommon_Instance_DidDestroy(PP_Instance instance);
static void PPAPICommon_Instance_DidChangeView(PP_Instance instance,
		PP_Resource view);
static void PPAPICommon_Instance_DidChangeFocus(PP_Instance instance,
		PP_Bool has_focus);
static PP_Bool PPAPICommon_Instance_HandleDocumentLoad(PP_Instance instance,
		PP_Resource url_loader);
*/
int32_t PPAPICommon_InitializeModule(PP_Module a_module_id, PPB_GetInterface get_browser);

struct PP_Var CStrToVar(const char* str);
char* VprintfToNewString(const char* format, va_list args) PRINTF_LIKE(1, 0);
char* PrintfToNewString(const char* format, ...) PRINTF_LIKE(1, 2);

struct PP_Var GetDictVar(struct PP_Var var, const char* key);
int SetDictVar(struct PP_Var dict, const char* key, struct PP_Var var_value);

int ParsePayloadMessage(struct PP_Var message, struct PP_Var* out_id, struct PP_Var* out_payload);
int ParseCommandMessage(struct PP_Var message, const char** out_function, struct PP_Var* out_params);

void PostStringMessage(const char* format, ...);
int PostIdMessage(struct PP_Var var_id, struct PP_Var var_message);

int AddToMap(void** map, int max_map_size, void* object);
int RemoveFromMap(void** map, int max_map_size, int i);
uint32_t GetNumParams(struct PP_Var params);
int GetParamString(struct PP_Var params, uint32_t index, char** out_string, uint32_t* out_string_len, const char** out_error);
int GetParamInt(struct PP_Var params, uint32_t index, int32_t* out_int, const char** out_error);
int GetParamIntArray(struct PP_Var params, uint32_t index, uint32_t* out_int, int32_t** out_array, const char** out_error);
int GetParamDoubleArray(struct PP_Var params, uint32_t index, uint32_t* out_int, double** out_array, const char** out_error);
void CreateResponse(struct PP_Var* response_var, const char* cmd, const char** out_error);
void AppendResponseVar(struct PP_Var* response_var, struct PP_Var value, const char** out_error);
void AppendResponseInt(struct PP_Var* response_var, int32_t value, const char** out_error);
void AppendResponseDouble(struct PP_Var* response_var, double value, const char** out_error);
void AppendResponseString(struct PP_Var* response_var, const char* value, const char** out_error);
void AppendResponseDoubleArray(struct PP_Var* response_var, uint32_t n, double *value, const char** out_error);


#define CHECK_PARAM_COUNT(name, expected)                                   \
  if (GetNumParams(params) != expected) {                                   \
    *out_error = PrintfToNewString(#name " takes " #expected " parameters." \
                                   " Got %d", GetNumParams(params));        \
    return 1;                                                               \
  }

#define PARAM_STRING(index, var)                                    \
  char* var;                                                        \
  uint32_t var##_len;                                               \
  if (GetParamString(params, index, &var, &var##_len, out_error)) { \
    return 1;                                                       \
  }

#define PARAM_INT(index, var)                        \
  int32_t var;                                       \
  if (GetParamInt(params, index, &var, out_error)) { \
    return 1;                                        \
  }

#define PARAM_INT_ARRAY(index, n, var) \
  uint32_t n; \
  int32_t *var; \
  if (GetParamIntArray(params, index, &n, &var, out_error)) { \
    return 1; \
  }

#define PARAM_DOUBLE_ARRAY(index, n, var) \
  uint32_t n; \
  double *var; \
  if (GetParamDoubleArray(params, index, &n, &var, out_error)) { \
    return 1; \
  }

#define CREATE_RESPONSE(name) CreateResponse(output, #name, out_error)
#define RESPONSE_STRING(var) AppendResponseString(output, var, out_error)
#define RESPONSE_INT(var) AppendResponseInt(output, var, out_error)
#define RESPONSE_DOUBLE(var) AppendResponseDouble(output, var, out_error)
#define RESPONSE_DOUBLE_ARRAY(n, var) AppendResponseDoubleArray(output, n, var, out_error)


typedef int (*HandleFunc)(struct PP_Var params,
                          struct PP_Var* out_var,
                          const char** error);

extern PP_Instance g_instance;
extern PPB_GetInterface g_get_browser_interface;

extern PPB_Var* g_ppb_var;//_interface;
extern PPB_VarArray* g_ppb_var_array;//_interface;
extern PPB_VarDictionary* g_ppb_var_dictionary;//_interface;
extern PPB_Messaging* g_ppb_messaging;//_interface;
extern PPB_Instance* g_ppb_instance;//_interface;
extern PPB_VarArrayBuffer* g_ppb_var_array_buffer;//_interface;

#define GET_INTERFACE(var, type, name)            \
  var = (type*)(get_browser(name));               \
  if (!var) {                                     \
    printf("Unable to get interface " name "\n"); \
    return PP_ERROR_FAILED;                       \
  }


static PP_Bool PPAPICommon_Instance_DidCreate(PP_Instance instance,
		uint32_t argc, const char* argn[], const char* argv[]) {
	g_instance = instance;
	return PP_TRUE;
}

static void PPAPICommon_Instance_DidDestroy(PP_Instance instance) {
}

static void PPAPICommon_Instance_DidChangeView(PP_Instance instance,
		PP_Resource view) {
}

static void PPAPICommon_Instance_DidChangeFocus(PP_Instance instance,
		PP_Bool has_focus) {
}

static PP_Bool PPAPICommon_Instance_HandleDocumentLoad(PP_Instance instance,
		PP_Resource url_loader) {
	return PP_FALSE;
}

static PPP_Instance g_instance_interface = {
		&PPAPICommon_Instance_DidCreate,
		&PPAPICommon_Instance_DidDestroy,
		&PPAPICommon_Instance_DidChangeView,
		&PPAPICommon_Instance_DidChangeFocus,
		&PPAPICommon_Instance_HandleDocumentLoad
};

#endif /* NACL_MODULE_H_ */
