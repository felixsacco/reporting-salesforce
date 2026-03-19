/**
 * @description Results display component for query results.
 *              Enhanced to display field labels in column headers instead of API names.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
import { LightningElement, api } from "lwc";

export default class ResultsDisplay extends LightningElement {
  columns = [];
  data = [];
  recordCount = 0;

  /**
   * @description Updates the results display with new data and field labels.
   * @param {Array} results - Array of SObject records
   * @param {Array} fields - Array of field API names
   * @param {String} objectType - The object type being queried
   * @param {Object} fieldLabels - Map of API names to labels {apiName: label}
   */
  @api
  updateResults(results, fields, objectType, fieldLabels) {
    this.recordCount = results.length;

    // Build columns dynamically based on selected fields
    this.columns = fields.map((field) => {
      const column = {
        label: fieldLabels[field], // Use label from map
        fieldName: field,
        type: this.getFieldType(field)
      };

      // Make Id and Name fields clickable links
      if (field === "Id" || field === "Name" || field === "Title") {
        column.type = "url";
        column.fieldName = field + "Link";
        column.typeAttributes = {
          label: { fieldName: field },
          target: "_blank"
        };
      }

      return column;
    });

    // Process data for datatable
    this.data = results.map((record) => {
      const processedRecord = { Id: record.Id };
      fields.forEach((field) => {
        processedRecord[field] = record[field];

        // Add link fields for Id, Name, and Title
        if (
          (field === "Id" || field === "Name" || field === "Title") &&
          record[field]
        ) {
          processedRecord[field + "Link"] = `/${record.Id}`;
        }
      });
      return processedRecord;
    });
  }

  /**
   * @description Determines the data type for a field to enable proper formatting in datatable.
   * @param {String} fieldName - The API name of the field
   * @returns {String} The field type (date, number, or text)
   */
  getFieldType(fieldName) {
    // Define field types for proper formatting
    const dateFields = ["CreatedDate", "LastModifiedDate", "SystemModstamp"];
    const numberFields = ["BodyLength", "ContentSize", "NumberOfEmployees"];

    if (dateFields.includes(fieldName)) {
      return "date";
    } else if (numberFields.includes(fieldName)) {
      return "number";
    }
    return "text";
  }

  get hasResults() {
    return this.data.length > 0;
  }

  get noResults() {
    return this.data.length === 0;
  }
}