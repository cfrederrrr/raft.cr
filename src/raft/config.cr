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


struct Raft::Config
  alias Raw = Hash(String, String | Int32 | Hash(String, String | Int32))

  getter cluster : ::Raft::Config::Cluster
  getter service : ::Raft::Config::Service
  getter heartbeat : Time::Span
  getter tls : OpenSSL::SSL::Context::Server?
  getter peers : Array(::Raft::Config::Peer)

  def self.new(general : Raw, cluster : Raw, service : Raw)
    s_uri = URI.parse(s_addr)
    s_uri = URI.parse("raft://" + s_addr) if s_addr == s_uri.path
    s_uri.port = 4920 if (s_uri.port.nil? && s_uri.scheme == "raft")
    service_adder = Socket::IPAddress.new(s_uri.host, s_uri.port)
    cluster = ::Raft::Config::Cluster.new
    new cluster, service, heartbeat, tls
  end

  def initialize(@cluster, @service, @heartbeat, @tls)
  end
end

struct Raft::Config::Peer
  getter address : URI
  getter heartbeat : Time::Span

  def initialize(@address, @heartbeat)
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
  getter address : URI
  getter certfile : String?
  getter pkeyfile : String?
  getter heartbeat : Time::Span

  def self.new(addr : String, cert : String?, pkey : String?, hbeat : Int)
    uri = URI.parse(p_addr)
    uri = URI.parse("raft://" + p_addr)
    uri.port = 4291 if (p_uri.port.nil? && p_uri.scheme == "raft")
    cluster_addr = Socket::IPAddress.new(p_uri.host, p_uri.port)
    heartbeat = Time::Span.new(nanoseconds: hbeat * 1_000_000)
    new cluster_addr, cert, pkey, heartbeat
  end

  def initialize(@address, @certfile, @pkeyfile, @heartbeat)
  end
end

{% begin %}
  {% for lang, const in {"json"=>"JSON", "yaml"=>"YAML", "ini"=>"INI"} %}
    {% if @type.has_constant?(const) %}

def Raft::Config.from_{{lang.id}}(data : String)
  conf = {{const.id}}.parse(data)

  general = conf[""]? || conf["general"]? || conf
  cluster_conf = conf["cluster"]
  service_conf = conf["service"]
  heartbeat = general["heartbeat"]
  tls = conf["tls"]? || general["tls"]?
  {% if lang == "ini" %}
  # the "defined_sections" are what they sound like - sections that include
  # known data. non-defined sections are all regarded as peers. the section name
  # will be the initialized @id of the peer, but may change as the peer
  # responds
  defined_sections = ["cluster", "service", "general", "", "tls"]
  peers = [] of ::Raft::Config::Peer
  sections = conf.each do |key, val|
    next if defined_sections.includes?(key)
    peer = val
    peer["id"] = key
    peers.push(peer)
  end
  new general, cluster_conf, service_conf, heartbeat, tls
  {% else %}
  new general.as_h, cluster_conf.as_h, service_conf.as_h, heartbeat.as_s, tls.as_h
  {% end %}
end

def Raft::Server::Config.load_{{lang.id}}(file : String)
  Raft::Server::Config.from_{{lang.id}}(File.read(file))
end

    {% end %}
  {% end %}
{% end %}
