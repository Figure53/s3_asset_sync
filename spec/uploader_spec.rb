# encoding: utf-8
require 'spec_helper'
require 'mock_aws'

require 's3_asset_sync/uploader'

describe S3AssetSync::Uploader do
  context "with single thread uploader and valid bucket" do
    before {
      @bucket = MockAWS::Bucket.new('fake')

      spec_path = File.dirname(__FILE__)
      fixtures_path = File.join(spec_path, 'fixtures')

      @uploader = S3AssetSync::Uploader.new(@bucket, fixtures_path, spec_path, 1)
    }

    it "should upload all files" do
      expect {
        @uploader.upload!
      }.to_not raise_error

      expect(@bucket.objects.size).to eq(7)

      expect(@bucket.objects['fixtures/file_a.txt'].metadata[:content_type]).to eq('text/plain')
      expect(@bucket.objects['fixtures/file_a.txt'].content).to eq("a\n")

      expect(@bucket.objects['fixtures/account-login.svg'].metadata[:content_type]).to eq('image/svg+xml')
    end
  end
end

