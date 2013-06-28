require 'spec_helper'

describe "a configured imagemagick app" do

  let(:app){ test_app }

  describe "convert command path" do

    it "should default to 'convert'" do
      app.configure do
        use :imagemagick
      end
      app.get_processor(:convert).command_line.convert_command.should == 'convert'
    end

    it "should allow configuring" do
      app.configure do
        use :imagemagick do
          convert_command '/usr/eggs/convert'
        end
      end
      app.get_processor(:convert).command_line.convert_command.should == '/usr/eggs/convert'
    end

  end

  describe "analysers" do
    let(:app){ test_app.configure_with(:imagemagick) }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

    it "should return the width" do
      image.width.should == 280
    end

    it "should return the height" do
      image.height.should == 355
    end

    it "should return the aspect ratio" do
      image.aspect_ratio.should == (280.0/355.0)
    end

    it "should say if it's portrait" do
      image.portrait?.should be_true
      image.portrait.should be_true # for using with magic attributes
    end

    it "should say if it's landscape" do
      image.landscape?.should be_false
      image.landscape.should be_false # for using with magic attributes
    end

    it "should return the format" do
      image.format.should == "png"
    end

    it "should say if it's an image" do
      image.image?.should be_true
      image.image.should be_true # for using with magic attributes
    end

    it "should say if it's not an image" do
      suppressing_stderr do
        app.create("blah").image?.should be_false
      end
    end
  end

  describe "processors that change the url" do
    let(:app){ test_app.configure_with(:imagemagick).configure{ url_format '/:name' } }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

    describe "convert" do
      it "sanity check with format" do
        thumb = image.convert('-resize 1x1!', 'jpg')
        thumb.url.should =~ /^\/beach\.jpg\?job=\w+/
        thumb.width.should == 1
        thumb.format.should == 'jpeg'
        thumb.meta['format'].should == 'jpg'
      end

      it "sanity check without format" do
        thumb = image.convert('-resize 1x1!')
        thumb.url.should =~ /^\/beach\.png\?job=\w+/
        thumb.width.should == 1
        thumb.format.should == 'png'
        thumb.meta['format'].should be_nil
      end
    end

    describe "encode" do
      it "sanity check" do
        thumb = image.encode('jpg')
        thumb.url.should =~ /^\/beach\.jpg\?job=\w+/
        thumb.format.should == 'jpeg'
        thumb.meta['format'].should == 'jpg'
      end
    end
  end

  describe "other processors" do
    let(:app){ test_app.configure_with(:imagemagick) }
    let(:image){ app.fetch_file(SAMPLES_DIR.join('beach.png')) }

    describe "encode" do
      it "should encode the image to the correct format" do
        image.encode!('gif')
        image.format.should == 'gif'
      end

      it "should allow for extra args" do
        image.encode!('jpg', '-quality 1')
        image.format.should == 'jpeg'
        image.size.should == 1445
      end
    end

    describe "rotate" do
      it "should rotate by 90 degrees" do
        image.rotate!(90)
        image.width.should == 355
        image.height.should == 280
      end

      it "should not rotate given a larger height and the '>' qualifier" do
        image.rotate!(90, 'qualifier' => '>')
        image.width.should == 280
        image.height.should == 355
      end

      it "should rotate given a larger height and the '<' qualifier" do
        image.rotate!(90, 'qualifier' => '<')
        image.width.should == 355
        image.height.should == 280
      end
    end

  end

end
