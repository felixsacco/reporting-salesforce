// BluePrint for building a qeury filter
public class QueryFilterDto {
    @AuraEnabled public String fieldName { get; set; }
    @AuraEnabled public String operator { get; set; }
    @AuraEnabled public String value { get; set; }
}