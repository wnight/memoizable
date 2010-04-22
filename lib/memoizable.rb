autoload :YAML, 'yaml'
autoload :FileUtils, 'fileutils'
module Memoizable
  CACHEFILE="~/.memoizable/cache.yaml"
  class << self
    def writeFile contents, filename, append=nil
      FileUtils.mkdir(File.expand_path(File.dirname(filename))) unless File.exist?(File.expand_path(File.dirname(filename)))
      File.open( File.expand_path(filename), (append.nil? ? (File::WRONLY|File::TRUNC|File::CREAT) : ("a"))) {|f| f.write contents }
    end
    def readFile filename, maxlines=0
      i=0
      read_so_far=[]
      begin
        f=File.open(File.expand_path(filename), 'r')
        while (line=f.gets)
          break if maxlines!=0 and i >= maxlines
          read_so_far << line and i+=1
        end
      rescue Errno::ENOENT
      end
      read_so_far
    end
    def writeCache
      Memoizable.writeFile YAML.dump(CACHE), CACHEFILE
    end
    #Determine if CACHE has an unexpired key
    #key must be the CACHE key to lookup, expire_time is the number of seconds a record is considered new, or nil
    def has key, expire_time = nil
      return false unless CACHE.has_key? key
      return true unless expire_time
      return false if Time.at(CACHE[key][1]) < (Time.now - expire_time)
      true
    end
  end
  cache=YAML.load(Memoizable.readFile(CACHEFILE).join)
  if cache.respond_to? :has_key?
    CACHE=cache
  else
    CACHE={}
  end
  module ClassMethods
    def memoize(name, expire_time=nil)
      original = "__original__#{name}"
      alias_method original, name
      define_method(name) do |*args|
        key = [self.to_s.to_sym, name.to_sym, *args.collect {|arg| arg.dup }]
        unless Memoizable.has(key, expire_time)
          CACHE[key] = [send(original, *args), Time.now.to_i]
          Memoizable.writeFile YAML.dump(CACHE), CACHEFILE
        end
        CACHE[key][0]
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end
