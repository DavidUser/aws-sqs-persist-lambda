#include <aws/lambda-runtime/runtime.h>

#include <exception>

#include "consumer.h"

using namespace aws::lambda_runtime;

invocation_response my_handler(invocation_request const& request) try {
  ConsumeMessage();
  return invocation_response::success("Done!", "application/json");
} catch (std::exception& error) {
  return invocation_response::failure(error.what(), "application/json");
}

int main() {
  run_handler(my_handler);
  return 0;
}
