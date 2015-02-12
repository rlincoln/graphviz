#include "ppapi/cpp/instance.h"
#include "ppapi/cpp/module.h"
#include "ppapi/cpp/var.h"

class EchoInstance : public pp::Instance {
 public:
  explicit EchoInstance(PP_Instance instance) : pp::Instance(instance) {}
  virtual ~EchoInstance() {}

  virtual void HandleMessage(const pp::Var& var_message) {
    PostMessage(var_message);
  }
};

class EchoModule : public pp::Module {
 public:
  EchoModule() : pp::Module() {}
  virtual ~EchoModule() {}

  virtual pp::Instance* CreateInstance(PP_Instance instance) {
    return new EchoInstance(instance);
  }
};

namespace pp {
Module* CreateModule() {
  return new EchoModule();
}
}  // namespace pp

