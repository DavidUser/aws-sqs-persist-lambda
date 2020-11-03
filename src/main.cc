#include <aws/core/utils/json/JsonSerializer.h>
#include <aws/lambda-runtime/runtime.h>

#include <exception>

#include "consumer.h"
#include "sqs.h"

using namespace aws::lambda_runtime;

invocation_response my_handler(invocation_request const& request) try {
  Aws::SDKOptions options;
  SimpleAws::Api api(options);
  {
    std::cout << "Request: " << request.payload << std::endl;
    Aws::Utils::Json::JsonValue payload = request.payload;
    Aws::Utils::Json::JsonView payloadView = payload.View();

    if (payload.WasParseSuccessful() && payloadView.KeyExists("Records")) {
      payloadView = payloadView.GetArray("Records").GetItem(0);
      Message message;
      message.SetMessageId(payloadView.GetString("messageId"));
      message.SetBody(payloadView.GetString("body"));

      ConsumeMessage(message);
    } else {
      ConsumeMessage();
    }
  }

  return invocation_response::success("Done!", "application/json");
} catch (std::exception& error) {
  std::cerr << error.what() << std::endl;
  return invocation_response::failure(error.what(), "application/json");
}

int main() {
  run_handler(my_handler);
  return 0;
}
