# -*- coding: utf-8 -*-
module Ezid
  class MetadataBuilder
  
  @@EZID = 'ezid'
  @@TITLE = 'title'
  @@PUBLICATION_YEAR = 'originInfoDateIssued'
  @@TYPE_OF_RESOURCE = 'typeOfResource'
  @@RELATED_IDENTIFIER_ISSN = 'identifierISSN'
  @@RELATED_IDENTIFIER_DOI = 'identifierDOI'
  @@RELATED_IDENTIFIER_ISBN = 'identifierISBN'
  @@RELATED_IDENTIFIER_HANDLE = 'identifierHDL'
  @@ABSTRACT = 'abstract'
     
  def initialize(item_id)  
    @item_id = item_id
    
    @authorsLastNames = Array.new
    @authorsFirstNames = Array.new 
    @personRoles = Array.new 
    
    @corporateNames = Array.new

    @subjects = Array.new
    
    @item = Item.find_by_id(@item_id, :include => [:item_type, {:values => :element}])
    @valuesMap = valuesToHash(@item.values)
    @contentXml = Nokogiri::XML(@item.to_xml)
    fillPersonArrays
    fillCorporateArrays
  end  
  
  def valuesToHash(values)
    valuesMap = Hash.new
    values.each do |value|
      if value.data != nil && !value.data.empty?
        valuesMap[value.element_code] = value.data.to_s
      end
      pushSubjects(value.element_code, value.data.to_s)
    end
    return valuesMap
  end   
  

  def pushSubjects(element_code, data)
         if element_code == 'subject' && !data.empty?
            @subjects << data.strip        
         end 
  end
  
  
  def fillPersonArrays
         
     @contentXml.css("namePersonal").each do |namePersonal|
       
        namePersonal.css('namePartFamily').each do |lastName|
          @authorsLastNames << lastName.text.strip
        end  
       
        namePersonal.css('namePartGiven').each do |firstName|
          @authorsFirstNames << firstName.text.strip
        end  
        
        namePersonal.css('role').each do |role|
          @personRoles << role.text.strip
        end      
        
     end

  end
  
  
  def fillCorporateArrays

    @contentXml.css('nameCorporate>namePart').each do |corporateName|
      Rails.logger.info "==== value: corporate name: " + corporateName.text.strip
      @corporateNames << corporateName.text.strip
    end 
  end    
  
  
  def getDoiXml

    builder = Nokogiri::XML::Builder.new do |xml|

    xml.resource('xmlns' => 'http://datacite.org/schema/kernel-3', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-3 http://schema.datacite.org/meta/kernel-3/metadata.xsd') { 
    #xml.resource('xmlns' => 'http://datacite.org/schema/kernel-2.2', 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance', 'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-2.2 http://schema.datacite.org/meta/kernel-2.2/metadata.xsd') { 
    
      xml.identifier('identifierType' => 'DOI') { xml.text @valuesMap[@@EZID] }
      
      xml.creators {
         getCreators.each do |name|
           xml.creator {
             xml.creatorName name
           }
         end
      }     
      
      xml.titles {
        xml.title @contentXml.css("title").first.text
      }  
         
      xml.publisher Ezid::Helper.getEzidConfig['publisher']
      xml.publicationYear @valuesMap[@@PUBLICATION_YEAR]
      addSubjects(xml)
      addContributers(xml)
      addDates(xml)
      xml.resourceType('resourceTypeGeneral' => Ezid::Helper.mapToResourceType(@valuesMap[@@TYPE_OF_RESOURCE]))
      addDescriptions(xml)
      addRelatedIdentifiers(xml)
      
    }
    end
    return builder.to_xml
  end  
  
  
  def addSubjects(xml)
    
    if !@subjects.empty?
      xml.subjects {
        @subjects.each do |subject|
          xml.subject subject
        end
      }
    end  
  end


  def addContributers(xml) 
    
    editors = getPersonsByRole('editor')
    moderators = getPersonsByRole('moderator')
    contributors = getPersonsByRole('contributor')
    
    if (!editors.empty? || !moderators.empty? || !contributors.empty?)
      xml.contributors {
        
        editors.each do |name|
          xml.contributor('contributorType' => 'Editor') {
            xml.contributorName name
          }
        end

        moderators.each do |name|
          xml.contributor('contributorType' => 'Other') {
            xml.contributorName name
          }
        end
        
        contributors.each do |name|
          xml.contributor('contributorType' => 'Other') {
            xml.contributorName name
          }
        end

      }
    end  
  end
  
  
  def addDescriptions(xml)
    if @valuesMap.has_key?(@@ABSTRACT)
      xml.descriptions {
        xml.description('descriptionType' => 'Abstract') { xml.text @valuesMap[@@ABSTRACT] }
      }
    end  
  end
  
  
  def addDates(xml)
      xml.dates {
        xml.date('dateType' => 'Created') {
          xml.text @item.created_at.to_s[0..9]
        }
        xml.date('dateType' => 'Updated') {
          xml.text @item.updated_at.to_s[0..9]
        }
      }
  end
  
  
  def addRelatedIdentifiers(xml)
    
    if @valuesMap.has_key?(@@RELATED_IDENTIFIER_ISSN) || 
       @valuesMap.has_key?(@@RELATED_IDENTIFIER_ISBN) || 
       @valuesMap.has_key?(@@RELATED_IDENTIFIER_DOI) || 
       @valuesMap.has_key?(@@RELATED_IDENTIFIER_HANDLE) 
       
      xml.relatedIdentifiers {
        
        if @valuesMap.has_key?(@@RELATED_IDENTIFIER_ISSN) 
          xml.relatedIdentifier('relatedIdentifierType' => 'ISSN','relationType' => 'IsPartOf') { xml.text @valuesMap[@@RELATED_IDENTIFIER_ISSN] }
        end
        
        if @valuesMap.has_key?(@@RELATED_IDENTIFIER_ISBN) 
          xml.relatedIdentifier('relatedIdentifierType' => 'ISBN','relationType' => 'IsPartOf') { xml.text @valuesMap[@@RELATED_IDENTIFIER_ISBN] }
        end
        
        if @valuesMap.has_key?(@@RELATED_IDENTIFIER_DOI) 
          xml.relatedIdentifier('relatedIdentifierType' => 'DOI','relationType' => 'IsVariantFormOf') { xml.text @valuesMap[@@RELATED_IDENTIFIER_DOI] }
        end
        
        if @valuesMap.has_key?(@@RELATED_IDENTIFIER_HANDLE) 
          xml.relatedIdentifier('relatedIdentifierType' => 'Handle','relationType' => 'IsVariantFormOf') { xml.text @valuesMap[@@RELATED_IDENTIFIER_HANDLE] }
        end
        
      }
    end  
  end

  def getCreators
    
    creators = getPersonsByRole('author')

     if creators.empty?
       return getCorporateNames
     else
       return creators
     end           
  end    
  
  def getPersonsByRole(role)
    
    persons = []
    
     @personRoles.each_with_index  do |item, index|

       if @personRoles[index] == role
          persons << @authorsLastNames[index] + ', ' + @authorsFirstNames[index]
       end   
     end  
     
     return persons
  end   
  
  def getCorporateNames
    corpNames = []
    @corporateNames.each do |name|
      corpNames << name
    end
    return corpNames
  end              

end
end