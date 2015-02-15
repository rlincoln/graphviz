/* Copyright (c) 2012 The Chromium Authors. All rights reserved.
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE file. */

#include "ppapi_common.h"
#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <limits.h>
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>

#include "ppapi/c/ppb_var.h"
#include "ppapi/c/ppb_instance.h"
#include "ppapi/c/ppb_messaging.h"
#include "ppapi/c/ppb_var_array.h"
#include "ppapi/c/ppb_var_array_buffer.h"
#include "ppapi/c/ppb_var_dictionary.h"

//#include "nacl_io/osdirent.h"

//#include "nacl_io_demo.h"

#define MAX_PARAMS 4

/**
 * A collection of the most recently allocated parameter strings. This makes
 * the Handle* functions below easier to write because they don't have to
 * manually deallocate the strings they're using.
 */
static char* g_ParamStrings[MAX_PARAMS];

PPB_Var* g_ppb_var = NULL;
PPB_Messaging* g_ppb_messaging = NULL;
PPB_Instance* g_ppb_instance = NULL;
PPB_VarArray* g_ppb_var_array = NULL;
PPB_VarDictionary* g_ppb_var_dictionary = NULL;
PPB_VarArrayBuffer* g_ppb_var_array_buffer = NULL;

PP_Instance g_instance = 0;
PPB_GetInterface g_get_browser_interface = NULL;

int32_t PPAPICommon_InitializeModule(PP_Module a_module_id, PPB_GetInterface get_browser) {
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

/**
 * Create a new PP_Var from a C string.
 * @param[in] str The string to convert.
 * @return A new PP_Var with the contents of |str|.
 */
struct PP_Var CStrToVar(const char* str) {
  return g_ppb_var->VarFromUtf8(str, strlen(str));
}

/**
 * Printf to a newly allocated C string.
 * @param[in] format A printf format string.
 * @param[in] args The printf arguments.
 * @return The newly constructed string. Caller takes ownership. */
char* VprintfToNewString(const char* format, va_list args) {
  va_list args_copy;
  int length;
  char* buffer;
  int result;

  va_copy(args_copy, args);
  length = vsnprintf(NULL, 0, format, args);
  buffer = (char*)malloc(length + 1); /* +1 for NULL-terminator. */
  result = vsnprintf(&buffer[0], length + 1, format, args_copy);
  if (result != length) {
    //assert(0);
    return NULL;
  }
  return buffer;
}

/**
 * Printf to a newly allocated C string.
 * @param[in] format A print format string.
 * @param[in] ... The printf arguments.
 * @return The newly constructed string. Caller takes ownership.
 */
char* PrintfToNewString(const char* format, ...) {
  va_list args;
  char* result;
  va_start(args, format);
  result = VprintfToNewString(format, args);
  va_end(args);
  return result;
}

/**
 * Vprintf to a new PP_Var.
 * @param[in] format A print format string.
 * @param[in] va_list The printf arguments.
 * @return A new PP_Var.
 */
static struct PP_Var VprintfToVar(const char* format, va_list args) {
  struct PP_Var var;
  char* string = VprintfToNewString(format, args);
  var = g_ppb_var->VarFromUtf8(string, strlen(string));
  free(string);
  return var;
}

/**
 * Convert a PP_Var to a C string.
 * @param[in] var The PP_Var to convert.
 * @return A newly allocated, NULL-terminated string.
 */
static const char* VarToCStr(struct PP_Var var) {
  uint32_t length;
  const char* str = g_ppb_var->VarToUtf8(var, &length);
  if (str == NULL) {
    return NULL;
  }

  /* str is NOT NULL-terminated. Copy using memcpy. */
  char* new_str = (char*)malloc(length + 1);
  memcpy(new_str, str, length);
  new_str[length] = 0;
  return new_str;
}

/**
 * Get a value from a Dictionary, given a string key.
 * @param[in] dict The dictionary to look in.
 * @param[in] key The key to look up.
 * @return PP_Var The value at |key| in the |dict|. If the key doesn't exist,
 *     return a PP_Var with the undefined value.
 */
struct PP_Var GetDictVar(struct PP_Var dict, const char* key) {
  struct PP_Var key_var = CStrToVar(key);
  struct PP_Var value = g_ppb_var_dictionary->Get(dict, key_var);
  g_ppb_var->Release(key_var);
  return value;
}

/**
 * Post a message to JavaScript.
 * @param[in] format A printf format string.
 * @param[in] ... The printf arguments.
 */
void PostMessage(const char* format, ...) {
  struct PP_Var var;
  va_list args;

  va_start(args, format);
  var = VprintfToVar(format, args);
  va_end(args);

  g_ppb_messaging->PostMessage(g_instance, var);
  g_ppb_var->Release(var);
}

/**
 * Given a message from JavaScript, parse it for functions and parameters.
 *
 * The format of the message is:
 * {
 *  "cmd": <function name>,
 *  "args": [<arg0>, <arg1>, ...]
 * }
 *
 * @param[in] message The message to parse.
 * @param[out] out_function The function name.
 * @param[out] out_params A PP_Var array.
 * @return 0 if successful, otherwise 1.
 */
int ParseMessage(struct PP_Var message,
                        const char** out_function,
                        struct PP_Var* out_params) {
  if (message.type != PP_VARTYPE_DICTIONARY) {
    return 1;
  }

  struct PP_Var cmd_value = GetDictVar(message, "cmd");
  *out_function = VarToCStr(cmd_value);
  g_ppb_var->Release(cmd_value);
  if (cmd_value.type != PP_VARTYPE_STRING) {
    return 1;
  }

  *out_params = GetDictVar(message, "args");
  if (out_params->type != PP_VARTYPE_ARRAY) {
    return 1;
  }

  return 0;
}

/**
 * Add |object| to |map| and return the index it was added at.
 * @param[in] map The map to add the object to.
 * @param[in] max_map_size The maximum map size.
 * @param[in] object The object to add to the map.
 * @return int The index of the added object, or -1 if there is no more space.
 */
int AddToMap(void** map, int max_map_size, void* object) {
  int i;
  assert(object != NULL);
  for (i = 0; i < max_map_size; ++i) {
    if (map[i] == NULL) {
      map[i] = object;
      return i;
    }
  }

  return -1;
}

/**
 * Remove an object at index |i| from |map|.
 * @param[in] map The map to remove from.
 * @param[in] max_map_size The size of the map.
 * @param[in] i The index to remove.
 */
int RemoveFromMap(void** map, int max_map_size, int i) {
  if (i >= 0 && i < max_map_size) {
      map[i] = NULL;
      return 1;
  }
  return 0;
}

/**
 * Get the number of parameters.
 * @param[in] params The parameter array.
 * @return uint32_t The number of parameters in the array.
 */
uint32_t GetNumParams(struct PP_Var params) {
  return g_ppb_var_array->GetLength(params);
}

/**
 * Get a parameter at |index| as a string.
 * @param[in] params The parameter array.
 * @param[in] index The index in |params| to get.
 * @param[out] out_string The output string.
 * @param[out] out_string_len The length of the output string.
 * @param[out] out_error An error message, if this operation failed.
 * @return int 0 if successful, otherwise 1.
 */
int GetParamString(struct PP_Var params,
                          uint32_t index,
                          char** out_string,
                          uint32_t* out_string_len,
                          const char** out_error) {
  if (index >= MAX_PARAMS) {
    *out_error = PrintfToNewString("Param index %u >= MAX_PARAMS (%d)",
                                   index, MAX_PARAMS);
    return 1;
  }

  struct PP_Var value = g_ppb_var_array->Get(params, index);
  if (value.type != PP_VARTYPE_STRING) {
    *out_error =
        PrintfToNewString("Expected param at index %d to be a string", index);
    return 1;
  }

  uint32_t length;
  const char* var_str = g_ppb_var->VarToUtf8(value, &length);

  char* string = (char*)malloc(length + 1);
  memcpy(string, var_str, length);
  string[length] = 0;

  /* Put the allocated string in g_ParamStrings. This keeps us from leaking
   * each parameter string, without having to do manual cleanup in every
   * Handle* function below.
   */
  free(g_ParamStrings[index]);
  g_ParamStrings[index] = string;


  *out_string = string;
  *out_string_len = length;
  return 0;
}

/**
 * Get a parameter at |index| as an int.
 * @param[in] params The parameter array.
 * @param[in] index The index in |params| to get.
 * @param[out] out_file The output int32_t.
 * @param[out] out_error An error message, if this operation failed.
 * @return int 0 if successful, otherwise 1.
 */
int GetParamInt(struct PP_Var params,
                       uint32_t index,
                       int32_t* out_int,
                       const char** out_error) {
  struct PP_Var value = g_ppb_var_array->Get(params, index);
  if (value.type != PP_VARTYPE_INT32) {
    *out_error = PrintfToNewString("Expected param at index %d to be an int32", index);
    return 1;
  }

  *out_int = value.value.as_int;
  return 0;
}

int GetParamIntArray(struct PP_Var params, uint32_t index, uint32_t *out_int,
        int32_t **out_array, const char** out_error) {
    struct PP_Var value = g_ppb_var_array->Get(params, index);
    if (value.type == PP_VARTYPE_ARRAY) {
        uint32_t l = g_ppb_var_array->GetLength(value);
        int32_t *x = malloc(sizeof(int32_t) * l);
        for (uint32_t i = 0; i < l; i++) {
            struct PP_Var elem = g_ppb_var_array->Get(value, i);
            if (elem.type == PP_VARTYPE_INT32) {
                x[i] = elem.value.as_int;
            } else if (elem.type == PP_VARTYPE_DOUBLE) {
                x[i] = (int32_t) elem.value.as_double;
            } else {
                *out_error = PrintfToNewString("Expected element at index %d to be an int32 (%d)", i, elem.type);
                return 1;
            }
        }
        *out_int = l;
        *out_array = x;
    } else if (value.type == PP_VARTYPE_ARRAY_BUFFER) {
        uint32_t byte_length = 0;
        PP_Bool ok = g_ppb_var_array_buffer->ByteLength(value, &byte_length);
        if (!ok) {
            *out_error = PrintfToNewString("Array buffer (int32) length %d", byte_length);
            return 1;
        }
        *out_int = byte_length / sizeof(int32_t);
        *out_array = (int32_t*) g_ppb_var_array_buffer->Map(value);
    } else {
        *out_error = PrintfToNewString("Expected param at index %d to be an array", index);
        return 1;
    }
    return 0;
}

int GetParamDoubleArray(struct PP_Var params, uint32_t index, uint32_t *out_int,
        double **out_array, const char** out_error) {
    struct PP_Var value = g_ppb_var_array->Get(params, index);
    if (value.type == PP_VARTYPE_ARRAY) {
        uint32_t l = g_ppb_var_array->GetLength(value);
        double *x = malloc(sizeof(double) * l);
        for (uint32_t i = 0; i < l; i++) {
            struct PP_Var elem = g_ppb_var_array->Get(value, i);
            if (elem.type == PP_VARTYPE_DOUBLE) {
                x[i] = elem.value.as_double;
            } else if (elem.type == PP_VARTYPE_INT32) {
                x[i] = (double) elem.value.as_int;
            } else {
                *out_error = PrintfToNewString("Expected element at index %d to be a double", i);
                return 1;
            }
        }
        *out_int = l;
        *out_array = x;
    } else if (value.type != PP_VARTYPE_ARRAY_BUFFER) {
        uint32_t byte_length = 0;
        PP_Bool ok = g_ppb_var_array_buffer->ByteLength(value, &byte_length);
        if (!ok) {
            *out_error = PrintfToNewString("Array buffer (double) length %d", byte_length);
            return 1;
        }
        *out_int = byte_length / sizeof(double);
        *out_array = (double*) g_ppb_var_array_buffer->Map(value);
    } else {
        *out_error = PrintfToNewString("Expected param at index %d to be an array", index);
        return 1;
    }
    return 0;
}

/**
 * Create a response PP_Var to send back to JavaScript.
 * @param[out] response_var The response PP_Var.
 * @param[in] cmd The name of the function that is being executed.
 * @param[out] out_error An error message, if this call failed.
 */
void CreateResponse(struct PP_Var* response_var,
                           const char* cmd,
                           const char** out_error) {
  PP_Bool result;

  struct PP_Var dict_var = g_ppb_var_dictionary->Create();
  struct PP_Var cmd_key = CStrToVar("cmd");
  struct PP_Var cmd_value = CStrToVar(cmd);

  result = g_ppb_var_dictionary->Set(dict_var, cmd_key, cmd_value);
  g_ppb_var->Release(cmd_key);
  g_ppb_var->Release(cmd_value);

  if (!result) {
    g_ppb_var->Release(dict_var);
    *out_error =
        PrintfToNewString("Unable to set \"cmd\" key in result dictionary");
    return;
  }

  struct PP_Var args_key = CStrToVar("args");
  struct PP_Var args_value = g_ppb_var_array->Create();
  result = g_ppb_var_dictionary->Set(dict_var, args_key, args_value);
  g_ppb_var->Release(args_key);
  g_ppb_var->Release(args_value);

  if (!result) {
    g_ppb_var->Release(dict_var);
    *out_error =
        PrintfToNewString("Unable to set \"args\" key in result dictionary");
    return;
  }

  *response_var = dict_var;
}

/**
 * Append a PP_Var to the response dictionary.
 * @param[in,out] response_var The response PP_var.
 * @param[in] value The value to add to the response args.
 * @param[out] out_error An error message, if this call failed.
 */
void AppendResponseVar(struct PP_Var* response_var,
                              struct PP_Var value,
                              const char** out_error) {
  struct PP_Var args_value = GetDictVar(*response_var, "args");
  uint32_t args_length = g_ppb_var_array->GetLength(args_value);
  PP_Bool result = g_ppb_var_array->Set(args_value, args_length, value);
  if (!result) {
    // Release the dictionary that was there before.
    g_ppb_var->Release(*response_var);

    // Return an error message instead.
    *response_var = PP_MakeUndefined();
    *out_error = PrintfToNewString("Unable to append value to result");
    return;
  }
}

/**
 * Append an int to the response dictionary.
 * @param[in,out] response_var The response PP_var.
 * @param[in] value The value to add to the response args.
 * @param[out] out_error An error message, if this call failed.
 */
void AppendResponseInt(struct PP_Var* response_var,
                              int32_t value,
                              const char** out_error) {
  AppendResponseVar(response_var, PP_MakeInt32(value), out_error);
}

void AppendResponseDouble(struct PP_Var* response_var,
                              double value,
                              const char** out_error) {
  AppendResponseVar(response_var, PP_MakeDouble(value), out_error);
}

/**
 * Append a string to the response dictionary.
 * @param[in,out] response_var The response PP_var.
 * @param[in] value The value to add to the response args.
 * @param[out] out_error An error message, if this call failed.
 */
void AppendResponseString(struct PP_Var* response_var,
                                 const char* value,
                                 const char** out_error) {
  struct PP_Var value_var = CStrToVar(value);
  AppendResponseVar(response_var, value_var, out_error);
  g_ppb_var->Release(value_var);
}

void AppendResponseDoubleArray(struct PP_Var* response_var,
                             uint32_t n,
                             double *x,
                             const char** out_error) {
    struct PP_Var var_array = g_ppb_var_array->Create();
    PP_Bool ok = g_ppb_var_array->SetLength(var_array, n);
    if (!ok) {
        return;
    }
    for (uint32_t i = 0; i < n; i++) {
        ok = g_ppb_var_array->Set(var_array, i, PP_MakeDouble(x[i]));
        if (!ok) {
        }
    }

/*
    struct PP_Var var_array = g_ppb_var_array_buffer->Create(sizeof(double) * n);
    double *xx = (double*) g_ppb_var_array_buffer->Map(var_array);
    for (uint32_t i = 0; i < n; i++) {
        xx[i] = x[i];
    }
    //memcpy(xx, *x, sizeof(double) * n);
    g_ppb_var_array_buffer->Unmap(var_array);
*/

    AppendResponseVar(response_var, var_array, out_error);
    g_ppb_var->Release(var_array);
}
