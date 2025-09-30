Win5x Diagnostics & Verification Guide

This checklist helps verify realtime sockets, payments, game phases, and reconciliation.

Realtime (Admin/User)
- Ensure envs:
  - Admin/User: VITE_API_URL and VITE_PROXY_TARGET → backend origin (e.g., http://172.20.10.4:3001)
- Observe backend logs on server start:
  - "Socket service initialized"
- Connect admin and user UIs, then check logs:
  - "Socket auth success … isAdmin:true/false"
- During a round verify logs fire:
  - "Broadcasted round started", "Broadcasted bet distribution"
- Fault injection:
  - Invalidate token → admin shows toast; backend logs auth error
  - Kill socket temporarily → admin shows reconnect toasts; Bets-by-Number updates via fallback within 30s and shows "Last updated"

Payments E2E
- Create test user (optional):
  - pnpm ts-node packages/backend/src/scripts/createTestUser.ts
- Simulate flows (prints tx IDs and balances):
  - cd packages/backend
  - pnpm ts-node src/scripts/simulatePayments.ts <username> <adminUser> <amount>
  - Example: pnpm ts-node src/scripts/simulatePayments.ts testuser15 admin 500
- Manual checks via UI:
  - Admin → Payments: approve/reject items; pagination & filters by status/user
  - Verify user balance updates and transactions presence
- API reconciliation:
  - Call /api/payment/admin/stats and confirm:
    - Totals equal DB sums of APPROVED deposits/withdrawals
    - Recent series reflect approvedAt timestamps

Game & Bets
- Phase timings: betting/spin/result durations match UI timers
- Bet validations:
  - Below min / above max / non-multiple-of-10 → rejected with error toast and server log
  - Insufficient balance → rejected; no transaction created
- Distribution cache:
  - After placing bets, logs show "Bet distribution cached" with key bet_distribution_<roundId>

Admin Diagnostics Page
- Navigate to /diagnostics in admin
  - Socket status (Connected/Disconnected)
  - Ping now; "Last ping" updates
  - Current round, phase, per-number amounts & counts
  - Payment stats and analytics snapshot

Common Issues
- Vite ws proxy error → set VITE_PROXY_TARGET to backend; confirm port 3001 reachable
- Socket auth failing → JWT secret mismatch or missing token
- Flow chart empty → no approvals yet or clock window; wait for 30s refresh

Useful Endpoints
- /api/game/current-round (public): current round + distribution
- /api/admin/analytics?period=daily
- /api/payment/admin/stats

Logs to Watch
- Backend: auth success/failure, round events, bet distribution cached/broadcasted, payment approve/reject with balances and tx IDs

