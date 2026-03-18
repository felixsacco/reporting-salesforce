/**
 * @description Data Transfer Object (DTO) representing a single filter condition in a query.
 *              Contains the field name, operator, and value(s) for filtering.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
public class QueryFilterDto {
    /**
     * @description The API name of the field to filter on
     */
    @AuraEnabled 
    public String fieldName { get; set; }
    
    /**
     * @description The operator to use for comparison (e.g., '=', 'LIKE', 'IN')
     */
    @AuraEnabled 
    public String operator { get; set; }
    
    /**
     * @description The value(s) to filter by. For multi-value operators (IN, NOT IN, INCLUDES, EXCLUDES),
     *              this should be a comma or semicolon-separated string.
     */
    @AuraEnabled 
    public String value { get; set; }

    /**
     * @description Parses the value string into a list of individual values.
     *              Supports both comma-separated and semicolon-separated values.
     *              Used for operators like IN, NOT IN, INCLUDES, and EXCLUDES.
     * 
     * @return A List of trimmed, non-empty values. Returns empty list if value is null or blank.
     */
    public List<String> parseValues() {
        if (String.isBlank(this.value)) {
            return new List<String>();
        }
        
        // Support both comma and semicolon delimiters
        String delimiter = this.value.contains(';') ? ';' : ',';
        
        List<String> values = new List<String>();
        for (String val : this.value.split(delimiter)) {
            String trimmed = val.trim();
            if (String.isNotBlank(trimmed)) {
                values.add(trimmed);
            }
        }
        
        return values;
    }
}