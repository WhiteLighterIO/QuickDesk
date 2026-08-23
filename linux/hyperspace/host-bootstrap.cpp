#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

bool HasNonEmptyField(const std::string& json, const char* field) {
  const std::string needle = std::string("\"") + field + "\"";
  const auto key = json.find(needle);
  if (key == std::string::npos) return false;
  const auto colon = json.find(':', key + needle.size());
  if (colon == std::string::npos) return false;
  const auto quote1 = json.find('"', colon + 1);
  if (quote1 == std::string::npos) return false;
  const auto quote2 = json.find('"', quote1 + 1);
  return quote2 != std::string::npos && quote2 > quote1 + 1;
}

int Fail(const char* message, int code) {
  std::cerr << message << '\n';
  return code;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc != 2) {
    return Fail("usage: hyperspace-linux-host-bootstrap <host-config.json>", 64);
  }

  std::ifstream input(argv[1], std::ios::binary);
  if (!input) return Fail("HYPERSPACE_HOST_CONFIG_OPEN_FAILED", 65);

  std::ostringstream buffer;
  buffer << input.rdbuf();
  const std::string json = buffer.str();
  if (json.empty()) return Fail("HYPERSPACE_HOST_CONFIG_EMPTY", 66);

  const char* required[] = {"orgId", "machineId", "agentId", "sessionId", "displayId", "displays"};
  for (const char* field : required) {
    if (std::string(field) == "displays") {
      const auto key = json.find("\"displays\"");
      const auto array = key == std::string::npos ? std::string::npos : json.find('[', key);
      const auto object = array == std::string::npos ? std::string::npos : json.find('{', array);
      if (object == std::string::npos) return Fail("HYPERSPACE_DISPLAY_INVENTORY_REQUIRED", 67);
      continue;
    }
    if (!HasNonEmptyField(json, field)) return Fail("HYPERSPACE_IDENTITY_REQUIRED", 68);
  }

  // This process is intentionally a local bootstrap only. It MUST NOT open a
  // public listener or accept QuickDesk device IDs/access codes. The future
  // Chromium Remoting host is started only after the HyperSpace broker has
  // authenticated the session through the existing strict mTLS + Cloudflare
  // Access control plane and supplied this validated local configuration.
  std::cout << "HYPERSPACE_LINUX_HOST_CONFIG_ACCEPTED\n";
  std::cout << "HYPERSPACE_NETWORK_ADMISSION_BLOCKED_PENDING_BROKER\n";
  return 0;
}
