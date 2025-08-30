import { LightningElement, api } from 'lwc';

export default class BoeingSeatInfo extends LightningElement {
    @api selectedSeats = [];
    @api hoveredSeat;

    get hasSelectedSeats() {
        return this.selectedSeats && this.selectedSeats.length > 0;
    }

    get selectedSeatsInfo() {
        if (!this.selectedSeats || this.selectedSeats.length === 0) return '';
        return this.selectedSeats.map(seat => seat.id).join(', ');
    }

    get totalPrice() {
        if (!this.selectedSeats || this.selectedSeats.length === 0) return 0;
        return this.selectedSeats.reduce((sum, seat) => sum + seat.price, 0);
    }

    get hasHoveredSeat() {
        return this.hoveredSeat != null;
    }

    get hoveredSeatClass() {
        if (this.hoveredSeat) {
            return this.hoveredSeat.seatClass.replace('-', ' ').replace(/\b\w/g, l => l.toUpperCase());
        }
        return '';
    }

    get hoveredSeatPosition() {
        if (this.hoveredSeat) {
            return this.hoveredSeat.position.charAt(0).toUpperCase() + this.hoveredSeat.position.slice(1);
        }
        return '';
    }
}