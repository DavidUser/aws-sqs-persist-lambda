#pragma once

#include <aws/core/Aws.h>

namespace SimpleAws {

class Api {
 public:
  Api(Aws::SDKOptions &options) : options(options) { Aws::InitAPI(options); }
  virtual ~Api() { Aws::ShutdownAPI(options); }

 private:
  Aws::SDKOptions &options;
};

}  // namespace SimpleAws
