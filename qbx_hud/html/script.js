const $ = (id) => document.getElementById(id);
const CIRC = 2 * Math.PI * 18;

document.querySelectorAll('.ring-fg').forEach((el) => {
    el.style.strokeDasharray = CIRC;
});

const fmt = (n) => (Math.floor(n) || 0).toLocaleString('da-DK') + ' kr.';

function setRing(id, value) {
    const el = $(id);
    const v = Math.max(0, Math.min(100, value));
    el.querySelector('.ring-fg').style.strokeDashoffset = CIRC * (1 - v / 100);
    el.classList.toggle('low', v <= 20);
}

window.addEventListener('message', (e) => {
    const d = e.data;

    if (d.action === 'init') {
        $('title-text').textContent = d.name || 'SEKTION 8';
        $('unit').textContent = d.unit === 'mph' ? 'MPH' : 'KM/T';
    }

    if (d.action === 'visible') {
        document.body.style.display = d.show ? 'block' : 'none';
    }

    if (d.action === 'update') {
        document.body.style.display = d.paused ? 'none' : 'block';

        setRing('r-health', d.health);
        setRing('r-hunger', d.hunger);
        setRing('r-thirst', d.thirst);

        // Vest vises kun når man har en på
        $('r-armor').classList.toggle('hidden', d.armor <= 0);
        if (d.armor > 0) setRing('r-armor', d.armor);

        $('cash').textContent = fmt(d.cash);
        $('black').textContent = fmt(d.black);
        $('job').textContent = d.job;
        $('grade').textContent = d.grade;

        $('vehicle').classList.toggle('hidden', !d.inVehicle);
        if (d.inVehicle) {
            $('speed').textContent = d.speed;
            $('fuel-wrap').classList.toggle('hidden', !d.showFuel);
            $('fuel-pct').textContent = d.fuel + '%';
            $('fuel-bar').style.width = d.fuel + '%';
            $('fuel-bar').classList.toggle('low', d.fuel <= 20);
        }
    }
});
