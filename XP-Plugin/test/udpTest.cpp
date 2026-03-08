#include <vector>
#include <chrono>
#include <random>

#include "../XPlane.hpp"
#include "../cmake-build-debug/plane.pb.h"

Plane makePlane (const int32_t id, const float lat, const float lon, const int32_t alt, const int32_t trk,
                 const int32_t vs, const std::string &flight, const std::string &icao) {
    Plane plane;
    plane.set_id(id);
    plane.set_lat(lat);
    plane.set_lon(lon);
    plane.set_alt(alt);
    plane.set_trk(trk);
    plane.set_vs(vs);
    plane.set_flight(flight);
    plane.set_icao(icao);
    return plane;
}

inline bool randomBool () {
    static std::random_device rd;
    static std::mt19937 gen(rd());
    std::uniform_int_distribution<int> dis(0, 3);
    return dis(gen) % 2 == 0;
}

constexpr double ft2m = 0.3048;
constexpr std::string magicHead = {0x40, 0x79, 0x54, 0x20};

int main () {
    XPMPIUBS xp{};
    bool isMove{true}; // 开启移动逻辑
    std::vector<Plane> aircrafts;
    aircrafts.push_back(makePlane(0, 29.9486, 106.7211, 10000 * ft2m, 0, 0, "ID0", "A20N"));
    aircrafts.push_back(makePlane(1, 29.8683, 106.7527, 15000 * ft2m, 90, 1500, "ID1", "B738"));
    aircrafts.push_back(makePlane(2, 30.0391, 106.8773, 5000 * ft2m, 180, -1500, "ID2", "C172"));
    aircrafts.push_back(makePlane(3, 30.2008, 106.8126, 10000 * ft2m, 270, 1500, "ID3", "CONC"));
    while (true) {
        Planes planes_msg;
        for (auto &p : aircrafts) {
            if (isMove) {
                p.set_lat(p.lat() + (randomBool() ? 0.0015f : -0.0015f));
                p.set_lon(p.lon() + (randomBool() ? 0.0015f : -0.0015f));
            }
            planes_msg.add_planes()->CopyFrom(p);
        }
        std::string data = magicHead;
        data += static_cast<char>(0xff & aircrafts.size()); // 动态获取飞机数量
        planes_msg.AppendToString(&data);
        xp.sendData(std::make_shared<std::string>(std::move(data)));
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        xp.poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(900));
    }
    return 0;
}
