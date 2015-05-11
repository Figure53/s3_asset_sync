module MockAWS
  class BucketObject
    attr_accessor :content, :metadata, :key

    def initialize(key)
      @key = key
      @exists = false
    end

    def exists?
      # always attempt upload
      @exists
    end

    def write(content, metadata={})
      @content = content
      @metadata = metadata
      @exists = true
    end
  end

  class Bucket
    attr_accessor :objects

    def initialize(key)
      @name = key
      @objects = Hash.new {|h, k| h[k] = BucketObject.new(k)}
    end

    def exists?
      true
    end
  end

  class S3
    attr_reader :buckets

    def initialize(options={})
      @buckets = Hash.new {|h, k| h[k] = Bucket.new(k)}
    end
  end
end
