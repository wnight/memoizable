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
  end
  CACHE = YAML.load(Memoizable.readFile(CACHEFILE).join)
  module ClassMethods
    def memoize(name)
      original = "__original__#{name}"
      alias_method original, name
      define_method(name) do |*args|
        key= self.to_s.unpack("a*")<<name.to_s.unpack("a*")<<args
        unless CACHE.has_key? key
          CACHE[key] = send(original, *args)
          Memoizable.writeFile YAML.dump(CACHE), CACHEFILE
        end
        CACHE[key]
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end
