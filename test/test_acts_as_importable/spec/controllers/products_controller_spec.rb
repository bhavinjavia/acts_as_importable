require 'spec_helper'

describe ProductsController do
  include ImportHelperMethods

  describe "POST 'upload'" do
    it "should redirect to import" do
      post 'upload'
      response.should redirect_to import_products_path
    end

    it "should accept and save an uploaded CSV file" do
      source_filename = File.dirname(__FILE__) + '/../test_data/dummy.csv'
      upload = Rack::Test::UploadedFile.new(source_filename, 'text/csv', true)

      post 'upload', :csv_file => upload
      response.should redirect_to import_products_path

      upload_filename = subject.send(:upload_file_name)
      File.read(upload_filename).should == File.read(source_filename)
    end

    it "should flash alert if non CSV file is uploaded" do
      source_filename = File.dirname(__FILE__) + '/../test_data/dummy.csv'
      upload = Rack::Test::UploadedFile.new(__FILE__, 'text/plain', true)

      post 'upload', :csv_file => upload
      flash[:alert].should == "Error! Invalid file, please select a csv file."
    end
  end

  describe "GET 'import'" do
    before do
      @store = Store.create!(:name => 'iTunes Store')
    end

    it "should render import form" do
      get 'import'
      response.should be_success
      response.should render_template("import")
    end

    it "should flash number of items imported on success" do
      product = Product.create!(:name => "iPhone 4", :price => 399.99)
      filename = create_test_file([product])
      Product.expects(:import).returns([product])
      get 'import'
      flash[:notice].should == "Import Successful - Imported 1 Products"
    end

    it "should flash alert on failure" do
      product = Product.create!(:name => "iPhone 4", :price => 399.99)
      filename = create_test_file([product])
      Product.expects(:import).raises(RuntimeError.new("Invalid date"))
      get 'import'
      flash[:alert].should == "Import Failed - No records imported due to errors. Invalid date"
    end

    it "should pass a :scoped context value to model.import" do
      product = Product.create!(:name => "iPhone 4", :price => 399.99)
      filename = create_test_file([product])
      Product.expects(:import).with(filename, has_entry(:scoped => @store)).returns([])
      get 'import'
    end

    it "should pass a :find_existing_by value to allow import to lookup existing records for update" do
      product = Product.create!(:name => "iPhone 4", :price => 399.99)
      filename = create_test_file([product])
      Product.expects(:import).with(filename, has_entry(:find_existing_by => :name)).returns([])
      get 'import'
    end
  end

  describe "GET 'export'" do
    let(:store) { Store.create!(:name => 'iTunes Store') }

    it "should send csv file" do
      get 'export'
      response.headers["Content-Type"].should == "text/csv; charset=iso-8859-1; header=present"
      response.headers["Content-Disposition"].should include("attachment")
    end

    it "should pass a :scoped context value to model.export" do
      Product.expects(:export).with(has_entry(:scoped => store)).returns([])
      get 'export'
    end
  end
end
