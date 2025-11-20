import { LightningElement, api, track } from 'lwc';

export default class ResultsDisplay extends LightningElement {
    @track columns = [];
    @track data = [];
    @track recordCount = 0;

    @api
    updateResults(results, fields, objectType) {
        this.recordCount = results.length;
        
        // Build columns dynamically based on selected fields
        this.columns = fields.map(field => {
            return {
                label: field,
                fieldName: field,
                type: this.getFieldType(field)
            };
        });

        // Process data for datatable
        this.data = results.map(record => {
            const processedRecord = { Id: record.Id };
            fields.forEach(field => {
                processedRecord[field] = record[field];
            });
            return processedRecord;
        });
    }

    getFieldType(fieldName) {
        // Define field types for proper formatting
        const dateFields = ['CreatedDate', 'LastModifiedDate'];
        const numberFields = ['BodyLength', 'ContentSize'];
        
        if (dateFields.includes(fieldName)) {
            return 'date';
        } else if (numberFields.includes(fieldName)) {
            return 'number';
        }
        return 'text';
    }

    get hasResults() {
        return this.data.length > 0;
    }

    get noResults() {
        return this.data.length === 0;
    }
}