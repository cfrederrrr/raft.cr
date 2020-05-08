require "uri"
require "socket"
require "openssl"

# Depending on the libraries you `require`, there are some convenience
# methods provided via macro for loading configs. For example, to load
# from `ini`, simply
#
# ```
# require "ini"
# require "raft"
# config = Raft::Server::Config.load_ini("/path/to/config.ini")
# ```
# or
# ```
# require "json"
# require "raft"
# config = Raft::Server::Config.load_json("/path/to/config.json")
# ```

alias Raft::Config::Raw =
  Hash(String, String | Int32 | Hash(String, String | Int32))

struct Raft::Config
  getter cluster : Port
  getter service : Port
  getter timeout : Time::Span
  getter tls : OpenSSL::SSL::Context::Server?

  def self.new(general : Raw, cluster : Raw, service : Raw)
    s_uri = URI.parse(s_addr)
    s_uri = URI.parse("raft://" + s_addr) if s_addr == s_uri.path
    s_uri.port = 4920 if (s_uri.port.nil? && s_uri.scheme == "raft")
    service_adder = Socket::IPAddress.new(s_uri.host, s_uri.port)
    cluster = Cluster.new
    new cluster, service, timeout, tls
  end

  def initialize(@cluster, @service, @timeout, @tls)
  end
end

struct Raft::Config::Service
  address : URI
  certfile : String?
  pkeyfile : String?

  def self.new(addr : String, cert : String?, pkey : String?)
    uri = URI.parse(p_addr)
    uri = URI.parse("raft://" + p_addr)
    uri.port = 4291 if (p_uri.port.nil? && p_uri.scheme == "raft")
    cluster_addr = Socket::IPAddress.new(p_uri.host, p_uri.port)
  end

  def initialize(@address, @certfile, @pkeyfile)
  end
end

struct Raft::Config::Cluster
  address : URI
  certfile : String?
  pkeyfile : String?
  timeout : Time::Span

  def self.new(addr : String, cert : String?, pkey : String?, tout : Int)
    uri = URI.parse(p_addr)
    uri = URI.parse("raft://" + p_addr)
    uri.port = 4291 if (p_uri.port.nil? && p_uri.scheme == "raft")
    cluster_addr = Socket::IPAddress.new(p_uri.host, p_uri.port)
    timeout = Time::Span.new(nanoseconds: tout * 1_000_000)
    new cluster_addr, cert, pkey, timeout
  end

  def initialize(@address, @certfile, @pkeyfile, @timeout)
  end
end

{% begin %}
  {% for lang, const in {"json"=>"JSON", "yaml"=>"YAML", "ini"=>"INI"} %}
    {% if @type.has_constant?(const) %}

def Raft::Config.from_{{lang.id}}(data : String)
  conf = {{const.id}}.parse(data)
  cluster = Listener.new(

  )

  general = conf[""]? || conf
  cluster_conf = conf["cluster"]
  service_conf = conf["service"]
  timeout = conf["cluster"]
  tls = conf["tls"]?
  new general, cluster_conf, service_conf, timeout, tls
end

def Raft::Server::Config.load_{{lang.id}}(file : String)
  Raft::Server::Config.from_{{lang.id}}(File.read(file))
end

    {% end %}
  {% end %}
{% end %}
