import { LightningElement, api } from 'lwc';

export default class BoeingSeatLegend extends LightningElement {
    @api showHeatMap = false;

    legendItems = [
        { type: 'available', label: 'Available', cssClass: 'seat-demo available' },
        { type: 'occupied', label: 'Occupied', cssClass: 'seat-demo occupied' },
        { type: 'selected', label: 'Selected', cssClass: 'seat-demo selected' },
        { type: 'business', label: 'Business Class', cssClass: 'seat-demo business-demo' },
        { type: 'economy-plus', label: 'Economy Plus', cssClass: 'seat-demo economy-plus-demo' },
        { type: 'economy', label: 'Economy', cssClass: 'seat-demo economy-demo' }
    ];

    get heatMapItems() {
        return [
            { color: '#FFD700', label: 'Most Popular (80-100)', style: 'background: #FFD700;' },
            { color: '#FFA500', label: 'High Demand (60-79)', style: 'background: #FFA500;' },
            { color: '#FF69B4', label: 'Moderate (40-59)', style: 'background: #FF69B4;' },
            { color: '#9370DB', label: 'Low Demand (20-39)', style: 'background: #9370DB;' },
            { color: '#4B0082', label: 'Least Popular (0-19)', style: 'background: #4B0082;' }
        ];
    }
}