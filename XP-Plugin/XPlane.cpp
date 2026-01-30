#include "XPlane.hpp"

XPMPIUBS::XPMPIUBS () : workGuard(asio::make_work_guard(io_context)) {
    infoSocket = ip::udp::socket(io_context, ip::udp::v4());
    infoSocket.set_option(ip::multicast::hops(1));
    infoEndpoint = ip::udp::endpoint(ip::make_address("239.1.73.16"), 57316);
}

void XPMPIUBS::sendData (const std::shared_ptr<std::string> &data) {
    asio::co_spawn(io_context, send(data), asio::detached);
}

void XPMPIUBS::poll () {
    io_context.poll();
}

asio::awaitable<void> XPMPIUBS::send (const std::shared_ptr<std::string> data) {
    co_await infoSocket.async_send_to(asio::buffer(*data), infoEndpoint, asio::use_awaitable);
}
