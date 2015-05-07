# encoding: utf-8
require 'spec_helper'
require 's3_asset_sync/uploader'

describe S3AssetSync::Uploader do
  context "with single thread uploader and valid bucket" do
    before {
      bucket = connect_bucket

      spec_path = File.dirname(__FILE__)
      fixtures_path = File.join(spec_path, 'fixtures')

      @uploader = S3AssetSync::Uploader.new(bucket, fixtures_path, spec_path, 8)
    }

    it "should upload all files" do
      expect {
        @uploader.upload!
      }.to_not raise_error
    end
  end
end

