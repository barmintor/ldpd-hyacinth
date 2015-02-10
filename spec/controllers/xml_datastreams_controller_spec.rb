require 'rails_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

RSpec.describe XmlDatastreamsController, :type => :controller do

  before { sign_in_admin_user() }

  # This should return the minimal set of attributes required to create a valid
  # XmlDatastream. As you add validations to XmlDatastream, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    skip("Add a hash of attributes valid for your model")
  }

  let(:invalid_attributes) {
    skip("Add a hash of attributes invalid for your model")
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # XmlDatastreamsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET index" do
    it "assigns all xml_datastreams as @xml_datastreams" do
      xml_datastream = XmlDatastream.create! valid_attributes
      get :index, {}, valid_session
      expect(assigns(:xml_datastreams)).to eq([xml_datastream])
    end
  end

  describe "GET show" do
    it "assigns the requested xml_datastream as @xml_datastream" do
      xml_datastream = XmlDatastream.create! valid_attributes
      get :show, {:id => xml_datastream.to_param}, valid_session
      expect(assigns(:xml_datastream)).to eq(xml_datastream)
    end
  end

  describe "GET new" do
    it "assigns a new xml_datastream as @xml_datastream" do
      get :new, {}, valid_session
      expect(assigns(:xml_datastream)).to be_a_new(XmlDatastream)
    end
  end

  describe "GET edit" do
    it "assigns the requested xml_datastream as @xml_datastream" do
      xml_datastream = XmlDatastream.create! valid_attributes
      get :edit, {:id => xml_datastream.to_param}, valid_session
      expect(assigns(:xml_datastream)).to eq(xml_datastream)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new XmlDatastream" do
        expect {
          post :create, {:xml_datastream => valid_attributes}, valid_session
        }.to change(XmlDatastream, :count).by(1)
      end

      it "assigns a newly created xml_datastream as @xml_datastream" do
        post :create, {:xml_datastream => valid_attributes}, valid_session
        expect(assigns(:xml_datastream)).to be_a(XmlDatastream)
        expect(assigns(:xml_datastream)).to be_persisted
      end

      it "redirects to the created xml_datastream" do
        post :create, {:xml_datastream => valid_attributes}, valid_session
        expect(response).to redirect_to(XmlDatastream.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved xml_datastream as @xml_datastream" do
        post :create, {:xml_datastream => invalid_attributes}, valid_session
        expect(assigns(:xml_datastream)).to be_a_new(XmlDatastream)
      end

      it "re-renders the 'new' template" do
        post :create, {:xml_datastream => invalid_attributes}, valid_session
        expect(response).to render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      let(:new_attributes) {
        skip("Add a hash of attributes valid for your model")
      }

      it "updates the requested xml_datastream" do
        xml_datastream = XmlDatastream.create! valid_attributes
        put :update, {:id => xml_datastream.to_param, :xml_datastream => new_attributes}, valid_session
        xml_datastream.reload
        skip("Add assertions for updated state")
      end

      it "assigns the requested xml_datastream as @xml_datastream" do
        xml_datastream = XmlDatastream.create! valid_attributes
        put :update, {:id => xml_datastream.to_param, :xml_datastream => valid_attributes}, valid_session
        expect(assigns(:xml_datastream)).to eq(xml_datastream)
      end

      it "redirects to the xml_datastream" do
        xml_datastream = XmlDatastream.create! valid_attributes
        put :update, {:id => xml_datastream.to_param, :xml_datastream => valid_attributes}, valid_session
        expect(response).to redirect_to(xml_datastream)
      end
    end

    describe "with invalid params" do
      it "assigns the xml_datastream as @xml_datastream" do
        xml_datastream = XmlDatastream.create! valid_attributes
        put :update, {:id => xml_datastream.to_param, :xml_datastream => invalid_attributes}, valid_session
        expect(assigns(:xml_datastream)).to eq(xml_datastream)
      end

      it "re-renders the 'edit' template" do
        xml_datastream = XmlDatastream.create! valid_attributes
        put :update, {:id => xml_datastream.to_param, :xml_datastream => invalid_attributes}, valid_session
        expect(response).to render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested xml_datastream" do
      xml_datastream = XmlDatastream.create! valid_attributes
      expect {
        delete :destroy, {:id => xml_datastream.to_param}, valid_session
      }.to change(XmlDatastream, :count).by(-1)
    end

    it "redirects to the xml_datastreams list" do
      xml_datastream = XmlDatastream.create! valid_attributes
      delete :destroy, {:id => xml_datastream.to_param}, valid_session
      expect(response).to redirect_to(xml_datastreams_url)
    end
  end

end
