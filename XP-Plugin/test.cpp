#include "XPlane.hpp"

int main () {
    XPMPIUBS xp{};
    std::string data{"Hello World "};
    int timer{};
    while (true) {
        data[11] = static_cast<char>('0' + timer);
        xp.sendData(std::make_shared<std::string>(data));
        std::this_thread::sleep_for(std::chrono::seconds(1));
        xp.poll();
        if (timer++ > 5)
            break;
    }
    return 0;
}
