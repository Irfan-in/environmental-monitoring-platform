// Integrated Environmental Monitoring Platform - Web Dashboard
let currentChartType = 'temp'; // 'temp' or 'hum'
let trendsChart = null;

// Initialize Chart.js
function initChart() {
  const ctx = document.getElementById('trendsChart').getContext('2d');
  trendsChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [],
      datasets: [
        {
          label: 'Indoor',
          data: [],
          borderColor: '#38bdf8',
          backgroundColor: 'rgba(56, 189, 248, 0.1)',
          borderWidth: 2,
          tension: 0.3,
          fill: true
        },
        {
          label: 'Outdoor',
          data: [],
          borderColor: '#fb923c',
          backgroundColor: 'rgba(251, 146, 60, 0.05)',
          borderWidth: 2,
          borderDash: [5, 5],
          tension: 0.3,
          fill: false
        }
      ]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          labels: { color: '#94a3b8', font: { size: 12 } }
        }
      },
      scales: {
        x: {
          ticks: { color: '#94a3b8', maxTicksLimit: 6 },
          grid: { color: 'rgba(255,255,255,0.05)' }
        },
        y: {
          ticks: { color: '#94a3b8' },
          grid: { color: 'rgba(255,255,255,0.05)' }
        }
      }
    }
  });
}

// Update Dashboard Data
async function refreshDashboard() {
  try {
    // 1. Fetch Indoor
    const inRes = await fetch('/api/indoor/latest');
    if (inRes.ok) {
      const inData = await inRes.json();
      document.getElementById('indoor-temp').textContent = inData.temperature.toFixed(1);
      document.getElementById('indoor-hum').textContent = inData.humidity.toFixed(1);
      document.getElementById('indoor-device-id').textContent = inData.device_id;
      document.getElementById('indoor-last-time').textContent = new Date(inData.timestamp).toLocaleTimeString();
    }

    // 2. Fetch Outdoor
    const outRes = await fetch('/api/outdoor/latest');
    if (outRes.ok) {
      const outData = await outRes.json();
      document.getElementById('outdoor-temp').textContent = outData.temperature.toFixed(1);
      document.getElementById('outdoor-hum').textContent = outData.humidity.toFixed(1);
      document.getElementById('outdoor-city').textContent = outData.city;
      document.getElementById('outdoor-wind').textContent = `${outData.wind_speed.toFixed(1)} km/h`;
      document.getElementById('outdoor-condition').textContent = outData.weather_desc;
    }

    // 3. Fetch Comparison
    const compRes = await fetch('/api/comparison');
    if (compRes.ok) {
      const comp = await compRes.json();
      if (comp.temp_diff !== null) {
        const signT = comp.temp_diff > 0 ? '+' : '';
        document.getElementById('comp-temp-diff').textContent = `${signT}${comp.temp_diff}°C`;
      }
      if (comp.hum_diff !== null) {
        const signH = comp.hum_diff > 0 ? '+' : '';
        document.getElementById('comp-hum-diff').textContent = `${signH}${comp.hum_diff}%`;
      }
      if (comp.indoor_heat_index !== null) {
        document.getElementById('comp-indoor-hi').textContent = `${comp.indoor_heat_index}°C`;
      }
      document.getElementById('comp-status').textContent = comp.comfort_assessment;
      document.getElementById('comp-summary').textContent = comp.status_summary;
    }

    // 4. Fetch Alerts
    const alertRes = await fetch('/api/alerts?limit=10');
    if (alertRes.ok) {
      const alerts = await alertRes.json();
      const listEl = document.getElementById('alerts-list');
      const countEl = document.getElementById('alert-count-badge');

      const unack = alerts.filter(a => !a.is_acknowledged);
      countEl.textContent = `${unack.length} Active`;
      countEl.style.display = unack.length > 0 ? 'inline-block' : 'none';

      if (alerts.length === 0) {
        listEl.innerHTML = `
          <div class="empty-state">
            <i class="fa-regular fa-circle-check"></i>
            <p>No active environmental alerts. All readings within safe thresholds.</p>
          </div>
        `;
      } else {
        listEl.innerHTML = alerts.map(a => `
          <div class="alert-item">
            <div>
              <strong>${a.message}</strong>
              <div style="font-size:10px; color:#94a3b8;">${new Date(a.timestamp).toLocaleTimeString()}</div>
            </div>
            ${!a.is_acknowledged ? `<button onclick="ackAlert(${a.id})" class="btn-sm" style="padding:2px 6px; font-size:10px;">Ack</button>` : '<span style="color:#10b981; font-size:10px;">✓ Ack</span>'}
          </div>
        `).join('');
      }
    }

    // 5. Fetch Historical Chart
    const histRes = await fetch('/api/history?limit=25');
    if (histRes.ok && trendsChart) {
      const histData = await histRes.json();
      const labels = histData.points.map(p => new Date(p.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
      
      let inValues, outValues, unit;
      if (currentChartType === 'temp') {
        inValues = histData.points.map(p => p.indoor_temperature);
        outValues = histData.points.map(p => p.outdoor_temperature);
        unit = '°C';
      } else {
        inValues = histData.points.map(p => p.indoor_humidity);
        outValues = histData.points.map(p => p.outdoor_humidity);
        unit = '%';
      }

      trendsChart.data.labels = labels;
      trendsChart.data.datasets[0].label = `Indoor (${unit})`;
      trendsChart.data.datasets[0].data = inValues;
      trendsChart.data.datasets[1].label = `Outdoor (${unit})`;
      trendsChart.data.datasets[1].data = outValues;
      trendsChart.update('none'); // smooth update
    }

  } catch (err) {
    console.error('Error updating dashboard:', err);
  }
}

// Acknowledge alert
async function ackAlert(id) {
  await fetch(`/api/alerts/${id}/ack`, { method: 'POST' });
  refreshDashboard();
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
  initChart();
  refreshDashboard();
  // Poll every 3 seconds
  setInterval(refreshDashboard, 3000);

  // Chart Toggle Pills
  document.querySelectorAll('.pill').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.pill').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentChartType = btn.getAttribute('data-chart');
      refreshDashboard();
    });
  });

  // Sync Weather Button
  const syncBtn = document.getElementById('btn-sync-weather');
  if (syncBtn) {
    syncBtn.addEventListener('click', async () => {
      syncBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Syncing...';
      await fetch('/api/outdoor/sync', { method: 'POST' });
      await refreshDashboard();
      syncBtn.innerHTML = '<i class="fa-solid fa-rotate"></i> Sync Weather';
    });
  }

  // Save Thresholds Button
  const saveThreshBtn = document.getElementById('btn-save-thresholds');
  if (saveThreshBtn) {
    saveThreshBtn.addEventListener('click', async () => {
      const minVal = parseFloat(document.getElementById('thresh-temp-min').value);
      const maxVal = parseFloat(document.getElementById('thresh-temp-max').value);
      await fetch('/api/alerts/thresholds/temperature', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ min_value: minVal, max_value: maxVal, is_enabled: true })
      });
      alert('Thresholds updated!');
      refreshDashboard();
    });
  }
});
