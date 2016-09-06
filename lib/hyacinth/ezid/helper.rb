# -*- coding: utf-8 -*-
require 'ezid/metadata_builder'
module Ezid
module Helper
  
  PREFIX = "doi:"
                 
  METADATA_FIELDS = { 'title' => 'datacite.title', 
                      'publisher' => 'datacite.publisher', 
                      'publicationyear' => 'datacite.publicationyear', 
                      'creator' => 'datacite.creator',
                      'resourcetype' =>  'datacite.resourcetype'}             
                 
  FIELDS_MAP = { 'title' => METADATA_FIELDS['title'], 
                 'originInfoDateIssued' => METADATA_FIELDS['publicationyear'] }                  
  
  TYPE_OF_RESOURCES_MAP = { 'text' => 'Text', 
                            'cartographic' => 'Other',
                            'notated music' => 'Text',
                            'sound recording--musical' => 'Sound',
                            'sound recording--nonmusical' => 'Sound',
                            'sound recording' => 'Sound',
                            'still image' => 'Image',
                            'moving image' => 'Audiovisual',
                            'three dimensional object' => 'PhysicalObject',
                            'software, multimedia' => 'Software',
                            'mixed material' => 'Other' }
  
  def self.get_new_ezid   
       
    ezidSession = getEzidSession()
    newEzid = ezidSession.mint()
    ezid = newEzid.identifier.sub(PREFIX, "")
    Rails.logger.info "======= new ezid created: " + ezid
    return ezid
  end    
  
  
  def self.getEzidRecord(ezidIdentifier)
       ezidSession = getEzidSession()
       ezidRecord = ezidSession.get(PREFIX + ezidIdentifier) 
       
       if(ezidRecord.nil? || ezidRecord.class.to_s == 'Ezid::ServerResponse')
         if (ezidRecord.class.to_s == 'Ezid::ServerResponse')
           Rails.logger.info "EZID error =  " + ezidRecord.to_s
         end
         raise 'Identifier ' + ezidIdentifier  +  ' not exists and can not be updated!'
       end

       return ezidRecord
  end
  
  
  def self.makeAuthorsString(authorsFirstNames, authorsLastNames, roles, corporateNames)

     authors = ''
     corporate = ''
     roles.each do |parent_id, role|
       
       if role != nil && !role.empty? && role == "author"
   
         if authorsLastNames[parent_id] != nil && !authorsLastNames[parent_id].empty?
            authors = authors + authorsLastNames[parent_id] + ', ' + authorsFirstNames[parent_id] + '; ' 
         end
         
         if corporateNames[parent_id] != nil && !corporateNames[parent_id].empty?  
             corporate = corporate + corporateNames[parent_id] + '; ' 
         end 
         
       end  
       
     end   
     
     if authors == ''
       authors = corporate
     end  
     
     return authors[0..-3]
  end
  
  
  def self.addElementValue(elementCode, values, mapHolder)
    
    values.each_pair do |value_id, data|
      value = Value.find_by_id(value_id)
      mapHolder[value.parent_id] = data
    end
  end
  
  def self.addRoleElementValue(elementCode, values, mapHolder)
    values.each_pair do |value_id, data|
      value = Value.find_by_id(value_id)
      if(data == 'author')
        mapHolder[value.parent_id] = data
      end  
    end
  end  
  
  
  
  def self.getAuthors(params)
    
    authorsLastNames = Hash.new
    authorsFirstNames = Hash.new 
    corporateNames = Hash.new
    roles = Hash.new 

     params.each_pair do |element_id, values|
       
       element = Element.find_by_id(element_id)
       elementCode = element.code
       
         if elementCode == 'namePartFamily'
            addElementValue(elementCode, values, authorsLastNames)      
         end
         
         if elementCode == 'namePartGiven'
            addElementValue(elementCode, values, authorsFirstNames)        
         end  
         
         if elementCode == 'namePart'
            addElementValue(elementCode, values, corporateNames)        
         end 
         
         if elementCode == 'role'
            addRoleElementValue(elementCode, values, roles)        
         end 

     end

     authors = makeAuthorsString(authorsFirstNames, authorsLastNames, roles, corporateNames)
     
     return authors

  end
  
  
  def self.updateMetadata(item_id, params)

     ezidMetadata = Hash.new()
     
     ezidMetadataBuilder = Ezid::MetadataBuilder.new(item_id)
     ezidMetadata['datacite'] = ezidMetadataBuilder.getDoiXml
     
     ezidIdentifier = get_item_ezid(item_id)

      if ezidIdentifier == nil || ezidIdentifier.empty?
        Rails.logger.info("EZID ezidIdentifier not found, update not processed")
      else   

        response_message = saveEzid(ezidIdentifier, ezidMetadata) 
        
        if(response_message.class.to_s == 'Ezid::ServerResponse' && response_message.errored?)
          ezidMetadata['_status'] = Ezid::ApiSession::UNAVAIL 
          response_message = saveEzid(ezidIdentifier, ezidMetadata)
        end  

      end
   
  end      
  
  
  def self.saveEzid(ezidIdentifier, ezidMetadata)  
       ezidSession = getEzidSession()
       response = ezidSession.create(PREFIX + ezidIdentifier, ezidMetadata)    
       return response
  end
  
  
  def self.updateTargetAndMakeEzidPublic(item_id, agg_pid)
    
     ezidIdentifier = findEzidByItemId(item_id)
     
     ezidMetadata = Hash.new()
     
     if(agg_pid != nil)
        ezidMetadata['_target'] = URI.unescape(makeEzidTargetUrl(agg_pid))
     end
     ezidMetadata['_status'] = Ezid::ApiSession::PUBLIC
     
     ezidMetadataBuilder = Ezid::MetadataBuilder.new(item_id)
     ezidMetadata['datacite'] = ezidMetadataBuilder.getDoiXml

     response_message = saveEzid(ezidIdentifier, ezidMetadata)
     
     ezidMetadata['response_message'] = response_message
     ezidMetadata['ezidIdentifier'] = ezidIdentifier

    return ezidMetadata
  end   
  
  
  def self.makeEzidTargetUrl(agg_pid)
    ezidConfig = getEzidConfig()  
    url = ezidConfig['target_url_base'] + agg_pid
    return  url
  end
  
  
  def self.findEzidByItemId(itemId)
    
    item = Item.find_by_id(itemId, :include => [:item_type, {:values => :element}])
    ezid = nil

    item.values.each do |value|

      if (value != nil && value.element_code == 'ezid')
        ezid = value.data
        break
      end   
                       
    end
    
    return ezid
    
  end
  
  
  def self.mapToResourceType(data)
     
     if TYPE_OF_RESOURCES_MAP.has_key?(data)
       return TYPE_OF_RESOURCES_MAP[data]
     else  
       return 'Text'
     end
  end      


  def self.getEzidSession()
    ezidConfig = getEzidConfig()    
    return Ezid::ApiSession.new(ezidConfig['ezid_user'], ezidConfig['ezid_password'], :doi, ezidConfig['shoulder'])    
  end
  
  
  def self.getEzidConfig(env=Rails.env)
    @all_config ||= (YAML.load_file("#{Rails.root}/config/ezid.yml") || {})
    return env.nil? ? @all_config : @all_config.fetch(env)
  end
  
  def self.get_item_ezid_value(item_id)
    conditions = {:item_id => item_id, :element_id => Ezid::DOI_ELEMENT_ID}
    return Value.find(:first, :conditions => conditions)
  end
  
  def self.get_item_ezid(item_id)

    value = get_item_ezid_value(item_id)
    if(value == nil)
      return nil
    else
      return value.data.to_s 
    end
      
  end
  
  def self.delete_ezid(ezid)
    
    if(ezid != nil && !ezid.empty?)
      ezidSession = getEzidSession()
      ezidSession.delete(PREFIX + ezid)
      Rails.logger.info "==== ezid: '" + ezid + "' is deleted ==="
    end
    return ezid
  end  
   
  
end
end
