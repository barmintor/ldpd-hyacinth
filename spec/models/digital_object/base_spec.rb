require 'rails_helper'

RSpec.describe DigitalObject::Base, :type => :model do
  
  let(:sample_item_digital_object_data) {
    dod = JSON.parse( fixture('sample_digital_object_data/new_item.json').read )
    dod['identifiers'] = ['item.' + SecureRandom.uuid] # random identifer to avoid collisions
    dod
  }
  

  describe "#initialize" do
    it "has a default dynamic_field_data value of {}" do
      digital_object = DigitalObject::Item.new()
      expect(digital_object.dynamic_field_data).to eq({})
    end
  end

  describe "#created_at " do
    it "returns a date" do
      new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
      new_item.set_digital_object_data(sample_item_digital_object_data, false)
      new_item.save
      date_today = Date.today
      expect(new_item.created_at.strftime("%m/%d/%Y")).to eq(date_today.strftime("%m/%d/%Y"))
      new_item.destroy
    end
  end

  describe "#updated_at " do
    it "returns a date" do
      new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
      new_item.set_digital_object_data(sample_item_digital_object_data, false)
      new_item.save
      date_today = Date.today
      expect(new_item.updated_at.strftime("%m/%d/%Y")).to eq(date_today.strftime("%m/%d/%Y"))
      new_item.destroy
    end
  end

  describe "#set_digital_object_data" do
    let(:sample_asset_digital_object_data) {
      dod = JSON.parse( fixture('sample_digital_object_data/new_asset.json').read )
      dod['identifiers'] = ['asset.' + SecureRandom.uuid] # random identifer to avoid collisions
      
      file_path = File.join(fixture_path(), '/sample_upload_files/lincoln.jpg')
      
      # Manually override import_file settings in the dummy fixture
      dod['import_file'] = {
        'import_type' => DigitalObject::Asset::IMPORT_TYPE_INTERNAL,
        'import_path' => file_path,
        'original_file_path' => file_path
      }
      
      dod
    }
    let(:sample_group_digital_object_data) {
      dod = JSON.parse( fixture('sample_digital_object_data/new_group.json').read )
      dod['identifiers'] = ['group.' + SecureRandom.uuid] # random identifer to avoid collisions
      dod
    }
    let(:second_sample_group_digital_object_data) {
      dod = JSON.parse( fixture('sample_digital_object_data/new_group.json').read )
      dod['identifiers'] = ['group.' + SecureRandom.uuid] # random identifer to avoid collisions
      dod
    }
    
    describe "raises exceptions for invalid data" do
      it "raises an exception for an object that references a parent digital object identifier that doesn't exist" do
        # Set parent identifier for new item data
        sample_item_digital_object_data['parent_digital_objects'] = [
          {
            'identifier' => 'this is an identifier that definitely does not exist --- ' + SecureRandom.uuid
          }
        ]
        
        new_item_with_parent_group = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        expect {
          new_item_with_parent_group.set_digital_object_data(sample_item_digital_object_data, false)
        }.to raise_error(Hyacinth::Exceptions::ParentDigitalObjectNotFoundError)
      end
      
      it "raises an exception for an object that references a project that doesn't exist" do
        # Set project for new item data
        sample_item_digital_object_data['project'] = {
          'string_key' => 'aaaaaaaaaaa_does_not_exist_aaaaaaaaaaa'
        }
        
        new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        expect {
          new_item.set_digital_object_data(sample_item_digital_object_data, false)
        }.to raise_error(Hyacinth::Exceptions::ProjectNotFoundError)
      end
      
      it "raises an exception for an object that references a publish target that doesn't exist" do
        # Set publish target for new item data
        sample_item_digital_object_data['publish_targets'] = [
          {
            'string_key' => 'zzzzzzzzzz_does_not_exist_zzzzzzzzzz'
          }
        ]
        
        new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        expect {
          new_item.set_digital_object_data(sample_item_digital_object_data, false)
        }.to raise_error(Hyacinth::Exceptions::PublishTargetNotFoundError)
      end
      
      it "raises an exception for a new object that references a pid that cannot be resolved to an existing Fedora object" do
        new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        sample_item_digital_object_data['pid'] = 'definitely:does_not_exist_zzzzz'
        expect {
          new_item.set_digital_object_data(sample_item_digital_object_data, false)
        }.to raise_error(Hyacinth::Exceptions::AssociatedFedoraObjectNotFoundError)
      end
      
      context "raises an exception for malformed controlled term field data" do
        it "rejects controlled term data that lacks both uri and value fields" do
          new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
          sample_item_digital_object_data['dynamic_field_data']['collection'] = [
            {  
              "collection_term" => {
                "custom_field" => "zzz",
              }
            }
          ]
          expect {
            new_item.set_digital_object_data(sample_item_digital_object_data, false)
          }.to raise_error(Hyacinth::Exceptions::MalformedControlledTermFieldValue)
        end
      end
      
    end
    
    describe "for DigitalObject::Group" do
    
      it "works for a Group that does not have a parent object" do
        group = DigitalObjectType.get_model_for_string_key(sample_group_digital_object_data['digital_object_type']['string_key']).new()
        group.set_digital_object_data(sample_group_digital_object_data, false)
        
        expect(group).to be_instance_of(DigitalObject::Group)
        expect(group.identifiers).to eq(sample_group_digital_object_data['identifiers'])
        expect(group.project.string_key).to eq('test')
        expect(group.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_1'])
        expect(group.dynamic_field_data).to eq(sample_group_digital_object_data['dynamic_field_data'])
        
        expect(group.created_by).to be_nil # Because we didn't set created_by
        expect(group.updated_by).to be_nil # Because we didn't set modified_by
      end
      
      it "works for a Group that references a parent Group" do
        # Create parent Group
        new_group = DigitalObjectType.get_model_for_string_key(sample_group_digital_object_data['digital_object_type']['string_key']).new()
        new_group.set_digital_object_data(sample_group_digital_object_data, false)
        new_group.save
        
        parent_group_pid = new_group.pid
        parent_group_identifier = new_group.identifiers.select{|identifier| identifier != parent_group_pid}.first
        
        # Set parent identifier for new Group data
        second_sample_group_digital_object_data['parent_digital_objects'] = [
          {
            'identifier' => parent_group_identifier
          }
        ]
        
        # Create child Group that references parent Group
        new_group_with_parent_group = DigitalObjectType.get_model_for_string_key(second_sample_group_digital_object_data['digital_object_type']['string_key']).new()
        new_group_with_parent_group.set_digital_object_data(second_sample_group_digital_object_data, false)
        
        expect(new_group_with_parent_group).to be_instance_of(DigitalObject::Group)
        expect(new_group_with_parent_group.identifiers).to eq(second_sample_group_digital_object_data['identifiers'])
        expect(new_group_with_parent_group.parent_digital_object_pids).to eq([parent_group_pid])
        expect(new_group_with_parent_group.project.string_key).to eq('test')
        expect(new_group_with_parent_group.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_1'])
        expect(new_group_with_parent_group.dynamic_field_data).to eq(second_sample_group_digital_object_data['dynamic_field_data'])
        
        expect(new_group_with_parent_group.created_by).to be_nil # Because we didn't set created_by
        expect(new_group_with_parent_group.updated_by).to be_nil # Because we didn't set modified_by
      end
    end
    
    describe "for DigitalObject::Item" do
    
      it "works for an Item that does not have a parent object" do
        item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        item.set_digital_object_data(sample_item_digital_object_data, false)
        
        expect(item).to be_instance_of(DigitalObject::Item)
        expect(item.identifiers).to eq(sample_item_digital_object_data['identifiers'])
        expect(item.project.string_key).to eq('test')
        expect(item.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_1', 'test_publish_target_2'])
        expect(item.dynamic_field_data).to eq(sample_item_digital_object_data['dynamic_field_data'])
        
        expect(item.created_by).to be_nil # Because we didn't set created_by
        expect(item.updated_by).to be_nil # Because we didn't set modified_by
      end
      
      it "works for an Item that references a parent Group" do
        # Create parent Group
        new_group = DigitalObjectType.get_model_for_string_key(sample_group_digital_object_data['digital_object_type']['string_key']).new()
        new_group.set_digital_object_data(sample_group_digital_object_data, false)
        new_group.save
        
        parent_group_pid = new_group.pid
        parent_group_identifier = new_group.identifiers.select{|identifier| identifier != parent_group_pid}.first
        
        # Set parent identifier for new item data
        sample_item_digital_object_data['parent_digital_objects'] = [
          {
            'identifier' => parent_group_identifier
          }
        ]
        
        # Create child Item that references parent Group
        new_item_with_parent_group = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        new_item_with_parent_group.set_digital_object_data(sample_item_digital_object_data, false)
        
        expect(new_item_with_parent_group).to be_instance_of(DigitalObject::Item)
        expect(new_item_with_parent_group.identifiers).to eq(sample_item_digital_object_data['identifiers'])
        expect(new_item_with_parent_group.parent_digital_object_pids).to eq([parent_group_pid])
        expect(new_item_with_parent_group.project.string_key).to eq('test')
        expect(new_item_with_parent_group.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_1', 'test_publish_target_2'])
        expect(new_item_with_parent_group.dynamic_field_data).to eq(sample_item_digital_object_data['dynamic_field_data'])
        
        expect(new_item_with_parent_group.created_by).to be_nil # Because we didn't set created_by
        expect(new_item_with_parent_group.updated_by).to be_nil # Because we didn't set modified_by
      end
    end
    
    describe "for DigitalObject::Asset" do
    
      it "works for an Asset that does not have a parent object" do
        asset = DigitalObjectType.get_model_for_string_key(sample_asset_digital_object_data['digital_object_type']['string_key']).new()
        asset.set_digital_object_data(sample_asset_digital_object_data, false)
        
        expect(asset).to be_instance_of(DigitalObject::Asset)
        expect(asset.identifiers).to eq(sample_asset_digital_object_data['identifiers'])
        expect(asset.project.string_key).to eq('test')
        expect(asset.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_2'])
        expect(asset.dynamic_field_data).to eq(sample_asset_digital_object_data['dynamic_field_data'])
        
        expect(asset.created_by).to be_nil # Because we didn't set created_by
        expect(asset.updated_by).to be_nil # Because we didn't set modified_by
      end
      
      it "works for an Asset that references a parent Item" do
        # Create parent Item
        new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        new_item.set_digital_object_data(sample_item_digital_object_data, false)
        new_item.save
        
        parent_item_pid = new_item.pid
        parent_item_identifier = new_item.identifiers.select{|identifier| identifier != parent_item_pid}.first
        
        # Set parent identifier for new asset data
        sample_asset_digital_object_data['parent_digital_objects'] = [
          {
            'identifier' => parent_item_identifier
          }
        ]
        
        # Create child Asset that references parent Item
        new_asset_with_parent_item = DigitalObjectType.get_model_for_string_key(sample_asset_digital_object_data['digital_object_type']['string_key']).new()
        new_asset_with_parent_item.set_digital_object_data(sample_asset_digital_object_data, false)
        
        expect(new_asset_with_parent_item).to be_instance_of(DigitalObject::Asset)
        expect(new_asset_with_parent_item.identifiers).to eq(sample_asset_digital_object_data['identifiers'])
        expect(new_asset_with_parent_item.parent_digital_object_pids).to eq([parent_item_pid])
        expect(new_asset_with_parent_item.project.string_key).to eq('test')
        expect(new_asset_with_parent_item.publish_targets.map{|publish_target| publish_target.string_key}.sort).to eq(['test_publish_target_2'])
        expect(new_asset_with_parent_item.dynamic_field_data).to eq(sample_asset_digital_object_data['dynamic_field_data'])
        
        expect(new_asset_with_parent_item.created_by).to be_nil # Because we didn't set created_by
        expect(new_asset_with_parent_item.updated_by).to be_nil # Because we didn't set modified_by
      end
    end
    
  end
  
  describe "#save" do
    it "saves the object, which can then be found using DigitalObject::Base.find" do
        item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        item.set_digital_object_data(sample_item_digital_object_data, false)
        item.save
        expect(DigitalObject::Base.find(item.pid).pid).to eq(item.pid)
    end
  
    it "can create a new DigitalObject for an existing Fedora object that isn't being tracked by Hyacinth, and preserves identifiers, parents and publish targets from that Fedora object" do
        
        existing_parent_object_pid = 'test:existing_parent_object'
        existing_parent_object = Collection.new(:pid => existing_parent_object_pid)
        existing_parent_object.save
        
        publish_target = PublishTarget.first
        publish_target_fedora_object = publish_target.fedora_object
        
        existing_object_pid = 'test:existingobject'
        existing_object_identifier = 'custom_identifier'
        content_aggregator = ContentAggregator.new(:pid => existing_object_pid)
        content_aggregator.datastreams['DC'].dc_identifier = [existing_object_identifier]
        content_aggregator.add_relationship(:cul_member_of, existing_parent_object.internal_uri)
        content_aggregator.add_relationship(:publisher, publish_target_fedora_object.internal_uri)
        content_aggregator.save
        
        expect(content_aggregator.pid).to eq(existing_object_pid) # New Fedora object has been assigned given pid
        expect(DigitalObject::Base.find_by_pid(existing_object_pid)).to eq(nil) # Hyacinth is not aware of any object with given pid
    
        # Create object with given pid
        sample_item_digital_object_data['pid'] = existing_object_pid
        item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
        item.set_digital_object_data(sample_item_digital_object_data, false)
        expect(item.pid).to eq(existing_object_pid) # pid should be set for the item
        
        # Save item, which should then refer to the existing Fedora object
        item.save
        
        expect(item.fedora_object).to eq(content_aggregator)
        expect(item.fedora_object.datastreams['DC'].dc_identifier.include?(existing_object_identifier)).to be(true)
        expect(item.parent_digital_object_pids.include?(existing_parent_object_pid)).to be(true)
        expect(item.publish_targets.include?(publish_target)).to be(true)
    end
  end

  describe '.get_class_for_fedora_object' do
    let!(:fedora_object) do
      fedora_object = cmodel.new
      fedora_object.datastreams['DC'].dc_type = model.const_get('VALID_DC_TYPES').clone
      fedora_object
    end

    subject { DigitalObject::Base.get_class_for_fedora_object(fedora_object) }

    context 'with a GenericResource' do
      let(:cmodel) { GenericResource }
      let(:model) { DigitalObject::Asset }

      it { is_expected.to be model }
    end

    context 'with a ContentAggregator' do
      let(:cmodel) { ContentAggregator }
      let(:model) { DigitalObject::Item }

      it { is_expected.to be model }
    end

    context 'with a BagAggregator' do
      let(:cmodel) { Collection }
      let(:model) { DigitalObject::Group }

      it { is_expected.to be model }
    end

    context 'with a FileSystem' do
      let(:cmodel) { Collection }
      let(:model) { DigitalObject::FileSystem }

      it { is_expected.to be model }
    end
    
    context 'with a PublishTarget' do
      let(:cmodel) { Concept }
      let(:model) { DigitalObject::PublishTarget }

      it { is_expected.to be model }
    end
  end

  describe "#value_for_field_name " do
    it "handle unallowed special substitution" do
      digital_object = DigitalObject::Item.new()
      arg = '$i_am_an_unallowed_substitution_field'
      expect(digital_object.value_for_field_name(arg,'')).to eq('Data unavailable')
    end

    it "handles $created_at" do
      new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
      new_item.set_digital_object_data(sample_item_digital_object_data, false)
      new_item.save
      arg = '$created_at'
      date_today = Date.today
      expect(new_item.value_for_field_name(arg,'').strftime("%m/%d/%Y")).to eq(date_today.strftime("%m/%d/%Y"))
      new_item.destroy
    end

    it "handles $updated_at" do
      new_item = DigitalObjectType.get_model_for_string_key(sample_item_digital_object_data['digital_object_type']['string_key']).new()
      new_item.set_digital_object_data(sample_item_digital_object_data, false)
      new_item.save
      arg = '$updated_at'
      date_today = Date.today
      expect(new_item.value_for_field_name(arg,'').strftime("%m/%d/%Y")).to eq(date_today.strftime("%m/%d/%Y"))
      new_item.destroy
    end
  end
end
