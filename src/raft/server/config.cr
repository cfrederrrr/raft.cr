require "uri"
require "socket"
require "openssl"

class Raft::Server::Config
  getter peer_addr : Socket::IPAddress
  getter serv_addr : Socket::IPAddress
  getter timeout : Time::Span
  getter tls : OpenSSL::SSL::Context::Server?

  def self.new(
      paddr : String,
      sadder : String,
      timeout milliseconds : Int32? = nil,
      tls : OpenSSL::SSL::Context::Server? = nil
    )

    peer_uri = URI.parse(paddr)
    peer_uri = URI.parse("raft://" + paddr) if paddr == peer_uri.path
    peer_uri.port = 4291 if peer_uri.port.nil? && peer_uri.scheme == "raft"
    peer_addr = Socket::IPAddress.new(peer_uri.host, peer_uri.port)

    serv_uri = URI.parse(saddr)
    serv_uri = URI.parse("raft://" + saddr) if saddr == serv_uri.path
    serv_uri.port = 4920 if serv_uri.port.nil? && serv_uri.scheme == "raft"
    serv_adder = Socket::IPAddress.new(serv_uri.host, serv_uri.port)

    timeout = Time::Span.new(nanoseconds: milliseconds * 1_000_000)

    new peer_addr, serv_addr, timeout, tls
  end

  def initialize(@peer_addr, @serv_addr, @timeout, @tls)
  end
end

{% begin %}
  {% for lang, const in {"json"=>"JSON", "yaml"=>"YAML", "ini"=>"INI"} %}
    {% if @type.has_constant?(const) %}

def Raft::Server::Config.from_{{lang.id}}(data : String)
  conf = {{const.id}}.parse(data)
  peer_addr = conf["peering"]["address"]
  serv_addr = conf["service"]["address"]
  timeout = conf["peering"]["timeout"]?
  tls = conf["tls"]?
  new peer_addr, serv_addr, timeout, tls
end

    {% end %}
  {% end %}
{% end %}
