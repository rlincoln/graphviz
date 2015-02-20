# Copyright (c) 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

VALID_TOOLCHAINS := pnacl

ifeq (,$(wildcard $(NACL_SDK_ROOT)/tools/oshelpers.py))
$(error NACL_SDK_ROOT is set to an invalid location: $(NACL_SDK_ROOT))
endif

TARGET = graphviz

include $(NACL_SDK_ROOT)/tools/common.mk

LIBS = ppapi pthread ppapi_common nacl_io gvplugin_core gvplugin_dot_layout gvc cgraph expat z cdt gvpr pathplan xdot gvplugin_neato_layout

CFLAGS = -Wall -std=gnu99 -I/usr/local/include/graphviz/
LDFLAGS = -L/usr/lib/ -L/usr/local/lib/graphviz/
NACL_CFLAGS += -Wall -I/nacl_sdk/pepper_38/toolchain/linux_pnacl/usr/local/include/graphviz
PNACL_LDFLAGS += -L/nacl_sdk/pepper_38/toolchain/linux_pnacl/usr/local/lib/graphviz


SOURCES = lib/graphviz.c

$(foreach src,$(SOURCES),$(eval $(call COMPILE_RULE,$(src),$(CFLAGS))))

ifneq (,$(or $(findstring pnacl,$(TOOLCHAIN)),$(findstring Release,$(CONFIG))))
$(eval $(call LINK_RULE,$(TARGET)_unstripped,$(SOURCES),$(LIBS),$(DEPS)))
$(eval $(call STRIP_RULE,$(TARGET),$(TARGET)_unstripped))
else
$(eval $(call LINK_RULE,$(TARGET),$(SOURCES),$(LIBS),$(DEPS)))
endif

$(eval $(call NMF_RULE,$(TARGET),))
