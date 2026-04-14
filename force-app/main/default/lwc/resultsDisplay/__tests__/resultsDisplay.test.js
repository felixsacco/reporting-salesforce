import { createElement } from 'lwc';
import ResultsDisplay from 'c/resultsDisplay';

const MOCK_DATA = [
    { Id: '00P0000001', Name: 'File1.jpg', BodyLength: 1024 },
    { Id: '00P0000002', Name: 'File2.jpg', BodyLength: 2048 }
];
const MOCK_FIELDS = ['Name', 'BodyLength'];
const MOCK_FIELD_LABELS = {
    Name: 'Name',
    BodyLength: 'Body Length'
};

describe('c-results-display', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('renders datatable when results provided', async () => {
        const element = createElement('c-results-display', {
            is: ResultsDisplay
        });
        document.body.appendChild(element);

        // Call the @api method
        element.updateResults(MOCK_DATA, MOCK_FIELDS, 'Attachment', MOCK_FIELD_LABELS);

        // Wait for re-render
        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).not.toBeNull();
        expect(datatable.data.length).toBe(2);
        
        // Check columns generation
        // Name should be url type based on component logic
        const nameCol = datatable.columns.find(col => col.fieldName === 'NameLink');
        expect(nameCol).toBeDefined();
        expect(nameCol.type).toBe('url');
    });

    it('shows no results message when data is empty', async () => {
        const element = createElement('c-results-display', {
            is: ResultsDisplay
        });
        document.body.appendChild(element);

        // Call with empty data
        element.updateResults([], MOCK_FIELDS, 'Attachment', MOCK_FIELD_LABELS);

        await Promise.resolve();

        const datatable = element.shadowRoot.querySelector('lightning-datatable');
        expect(datatable).toBeNull();

        const noResultsMsg = element.shadowRoot.querySelector('.slds-text-align_center');
        expect(noResultsMsg).not.toBeNull();
    });
});