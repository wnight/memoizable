autoload :YAML, 'yaml'
autoload :FileUtils, 'fileutils'
module Memoizable
  @cachefile||="~/.memoizable/cache.yaml"
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
      Memoizable.writeFile YAML.dump(@cache), @cachefile
    end
  end
  cache=YAML.load(Memoizable.readFile(@cachefile).join)
  unless @cache
    if cache.respond_to? :has_key?
      @cache=cache
    else
      @cache={}
    end
  end
  module ClassMethods
    def memoize(name)
      original = "__original__#{name}"
      alias_method original, name
      define_method(name) do |*args|
        key= self.to_s.unpack("a*")<<name.to_s.unpack("a*")<<args
        unless @cache.has_key? key
          @cache[key] = send(original, *args)
        end
        @cache[key]
      end
    end
  end
  
  def self.included(receiver)
    receiver.extend ClassMethods
  end
end
