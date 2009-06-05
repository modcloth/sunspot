require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'indexer' do
  describe 'when indexing an object' do
    it 'should index id' do
      session.index post
      connection.should have_add_with(:id => "Post #{post.id}")
    end

    it 'should index type' do
      session.index post
      connection.should have_add_with(:type => ['Post', 'BaseClass'])
    end

    it 'should index the array of objects supplied' do
      posts = Array.new(2) { Post.new }
      session.index posts
      connection.should have_add_with(
        { :id => "Post #{posts.first.id}" },
        { :id => "Post #{posts.last.id}" }
      )
    end

    it 'should index an array containing more than one type of object' do
      post1, comment, post2 = objects = [Post.new, Comment.new, Post.new]
      session.index objects
      connection.should have_add_with(
        { :id => "Post #{post1.id}", :type => ['Post', 'BaseClass'] },
        { :id => "Post #{post2.id}", :type => ['Post', 'BaseClass'] }
      )
      connection.should have_add_with(:id => "Comment #{comment.id}", :type => ['Comment', 'BaseClass'])
    end

    it 'should index text' do
      session.index(post(:title => 'A Title', :body => 'A Post'))
      connection.should have_add_with(:title_text => 'A Title', :body_text => 'A Post')
    end

    it 'should index text via a virtual field' do
      session.index(post(:title => 'backwards'))
      connection.should have_add_with(:backwards_title_text => 'backwards'.reverse)
    end

    it 'should correctly index a string attribute field' do
      session.index(post(:title => 'A Title'))
      connection.should have_add_with(:title_s => 'A Title')
    end

    it 'should correctly index an integer attribute field' do
      session.index(post(:blog_id => 4))
      connection.should have_add_with(:blog_id_i => '4')
    end

    it 'should correctly index a float attribute field' do
      session.index(post(:ratings_average => 2.23))
      connection.should have_add_with(:average_rating_f => '2.23')
    end

    it 'should allow indexing by a multiple-value field' do
      session.index(post(:category_ids => [3, 14]))
      connection.should have_add_with(:category_ids_im => ['3', '14'])
    end

    it 'should correctly index a time field' do
      session.index(post(:published_at => Time.parse('1983-07-08 05:00:00 -0400')))
      connection.should have_add_with(:published_at_d => '1983-07-08T09:00:00Z')
    end

    it 'should correctly index a boolean field' do
      session.index(post(:featured => true))
      connection.should have_add_with(:featured_b => 'true')
    end

    it 'should correctly index a false boolean field' do
      session.index(post(:featured => false))
      connection.should have_add_with(:featured_b => 'false')
    end

    it 'should not index a nil boolean field' do
      session.index(post)
      connection.should_not have_add_with(:featured_b)
    end

    it 'should correctly index a virtual field' do
      session.index(post(:title => 'The Blog Post'))
      connection.should have_add_with(:sort_title_s => 'blog post')
    end

    it 'should correctly index an external virtual field' do
      session.index(post(:category_ids => [1, 2, 3]))
      connection.should have_add_with(:primary_category_id_i => '1')
    end

    it 'should correctly index a field that is defined on a superclass' do
      Sunspot.setup(BaseClass) { string :author_name }
      session.index(post(:author_name => 'Mat Brown'))
      connection.should have_add_with(:author_name_s => 'Mat Brown')
    end

    it 'should commit immediately after index! called' do
      connection.should_receive(:add).ordered
      connection.should_receive(:commit).ordered
      session.index!(post)
    end

    it 'should remove an object from the index' do
      session.remove(post)
      connection.should have_delete("Post #{post.id}")
    end

    it 'should remove an object from the index and immediately commit' do
      connection.should_receive(:delete_by_id).ordered
      connection.should_receive(:commit).ordered
      session.remove!(post)
    end

    it 'should remove everything from the index' do
      session.remove_all
      connection.should have_delete_by_query("type:[* TO *]")
    end

    it 'should remove everything from the index and immediately commit' do
      connection.should_receive(:delete_by_query).ordered
      connection.should_receive(:commit).ordered
      session.remove_all!
    end

    it 'should be able to remove everything of a given class from the index' do
      session.remove_all(Post)
      connection.should have_delete_by_query("type:Post")
    end
  end

  describe 'dynamic fields' do
    it 'should index string data' do
      session.index(post(:custom_string => { :test => 'string' }))
      connection.should have_add_with(:"custom_string:test_s" => 'string')
    end

    it 'should index integer data with virtual accessor' do
      session.index(post(:category_ids => [1, 2]))
      connection.should have_add_with(:"custom_integer:1_i" => '1', :"custom_integer:2_i" => '1')
    end

    it 'should index float data' do
      session.index(post(:custom_fl => { :test => 1.5 }))
      connection.should have_add_with(:"custom_float:test_fm" => '1.5')
    end

    it 'should index time data' do
      session.index(post(:custom_time => { :test => Time.parse('2009-05-18 18:05:00 -0400') }))
      connection.should have_add_with(:"custom_time:test_d" => '2009-05-18T22:05:00Z')
    end

    it 'should index boolean data' do
      session.index(post(:custom_boolean => { :test => false }))
      connection.should have_add_with(:"custom_boolean:test_b" => 'false')
    end

    it 'should index multiple values for a field' do
      session.index(post(:custom_fl => { :test => [1.0, 2.1, 3.2] }))
      connection.should have_add_with(:"custom_float:test_fm" => %w(1.0 2.1 3.2))
    end
  end

  it 'should throw a NoMethodError only if a nonexistent type is defined' do
    lambda { Sunspot.setup(Post) { string :author_name }}.should_not raise_error
    lambda { Sunspot.setup(Post) { bogus :journey }}.should raise_error(NoMethodError)
  end

  it 'should throw a NoMethodError if a nonexistent field argument is passed' do
    lambda { Sunspot.setup(Post) { string :author_name, :bogus => :argument }}.should raise_error(ArgumentError)
  end

  it 'should throw an ArgumentError if an attempt is made to index an object that has no configuration' do
    lambda { session.index(Time.now) }.should raise_error(Sunspot::NoSetupError)
  end

  it 'should throw an ArgumentError if single-value field tries to index multiple values' do
    lambda do
      Sunspot.setup(Post) { string :author_name }
      session.index(post(:author_name => ['Mat Brown', 'Matthew Brown']))
    end.should raise_error(ArgumentError)
  end

  it 'should throw a NoAdapterError if class without adapter is indexed' do
    lambda { session.index(User.new) }.should raise_error(Sunspot::NoAdapterError)
  end

  it 'should throw an ArgumentError if a non-word character is included in the field name' do
    lambda do
      Sunspot.setup(Post) { string :"bad name" }
    end.should raise_error(ArgumentError)
  end

  private

  def config
    Sunspot::Configuration.build
  end

  def connection
    @connection ||= Mock::Connection.new
  end

  def session
    @session ||= Sunspot::Session.new(config, connection)
  end

  def post(attrs = {})
    @post ||= Post.new(attrs)
  end

  def last_add
    @connection.adds.last
  end

  def value_in_last_document_for(field_name)
    @connection.adds.last.last.field_by_name(field_name).value
  end

  def values_in_last_document_for(field_name)
    @connection.adds.last.last.fields_by_name(field_name).map { |field| field.value }
  end
end
