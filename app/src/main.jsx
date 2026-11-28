import React, { useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

const apiRoot = (import.meta.env.VITE_API_BASE_URL || '/api').replace(/\/+$/, '');
const statusNames = { confirmed: 'Approved', approved: 'Approved', pending: 'Pending', rejected: 'Rejected', cancelled: 'Cancelled', completed: 'Completed' };

function initials(name = '') {
  const words = name.trim().split(/\s+/).filter(Boolean);
  return `${words[0]?.[0] || '?'}${words.length > 1 ? words.at(-1)[0] : ''}`.toUpperCase();
}

function dateTime(value) {
  if (!value) return '—';
  const date = new Date(String(value).replace(' ', 'T'));
  if (Number.isNaN(date.getTime())) return String(value);
  return new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(date);
}

function dateWindow(start, end) {
  if (!start || !end) return '—';
  const a = new Date(String(start).replace(' ', 'T'));
  const b = new Date(String(end).replace(' ', 'T'));
  if (Number.isNaN(a.getTime()) || Number.isNaN(b.getTime())) return `${start} → ${end}`;
  const day = new Intl.DateTimeFormat(undefined, { dateStyle: 'medium' }).format(a);
  const time = new Intl.DateTimeFormat(undefined, { timeStyle: 'short' });
  return `${day} · ${time.format(a)}–${time.format(b)}`;
}

function toSqlDateTime(value) {
  return value ? (value.length === 16 ? `${value.replace('T', ' ')}:00` : value.replace('T', ' ')) : '';
}

function tomorrowAtTen() {
  const date = new Date(Date.now() + 24 * 60 * 60 * 1000);
  date.setHours(10, 0, 0, 0);
  const part = (number) => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${part(date.getMonth() + 1)}-${part(date.getDate())}T10:00`;
}

function badgeClass(status) {
  const value = String(status || '').toLowerCase();
  if (value === 'pending') return 'warn';
  if (['confirmed', 'approved'].includes(value)) return 'ok';
  if (value === 'rejected') return 'bad';
  if (value === 'completed') return 'accent';
  return 'neutral';
}

function StatusBadge({ status }) {
  const key = String(status || '').toLowerCase();
  return <span className={`badge ${badgeClass(key)}`}><span aria-hidden="true">{key === 'pending' ? '◷' : ['confirmed', 'approved', 'completed'].includes(key) ? '✓' : key === 'rejected' ? '×' : '•'}</span>{statusNames[key] || key || 'Unknown'}</span>;
}

function Icon({ name }) {
  const paths = {
    resources: <><rect x="4" y="4" width="7" height="7" rx="1"/><rect x="14" y="4" width="6" height="7" rx="1"/><rect x="4" y="14" width="7" height="6" rx="1"/><rect x="14" y="14" width="6" height="6" rx="1"/></>,
    bookings: <><rect x="4" y="5" width="16" height="15" rx="2"/><path d="M8 3v4M16 3v4M4 10h16M8 14h3M8 17h6"/></>,
    maintenance: <><path d="M14 6a5 5 0 0 0 6 6l-9 9-4-4 9-9a5 5 0 0 1-6-6l3 3 3-1 1-3-3-3z"/></>,
    activity: <path d="M4 13h4l3-8 4 14 3-6h2"/>
  };
  return <svg viewBox="0 0 24 24" aria-hidden="true">{paths[name]}</svg>;
}

function App() {
  const [token, setToken] = useState(() => localStorage.getItem('campusBookingToken') || '');
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('campusBookingUser') || 'null'); } catch { return null; }
  });
  const [authView, setAuthView] = useState('signin');
  const [signInEmail, setSignInEmail] = useState('');
  const [view, setView] = useState('resources');
  const [authMessage, setAuthMessage] = useState(null);
  const [authBusy, setAuthBusy] = useState(false);
  const [resourceList, setResourceList] = useState([]);
  const [bookings, setBookings] = useState([]);
  const [reports, setReports] = useState([]);
  const [bookingsLoading, setBookingsLoading] = useState(false);
  const [maintenanceLoading, setMaintenanceLoading] = useState(false);
  const [status, setStatus] = useState('Connecting');
  const [resourceError, setResourceError] = useState('');
  const [bookingError, setBookingError] = useState('');
  const [message, setMessage] = useState(null);
  const [logs, setLogs] = useState([]);
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('');
  const [availability, setAvailability] = useState('');
  const [selectedResource, setSelectedResource] = useState('');
  const [startTime, setStartTime] = useState(tomorrowAtTen);
  const [endTime, setEndTime] = useState(() => {
    const date = new Date(tomorrowAtTen());
    date.setHours(date.getHours() + 1);
    const part = (number) => String(number).padStart(2, '0');
    return `${date.getFullYear()}-${part(date.getMonth() + 1)}-${part(date.getDate())}T${part(date.getHours())}:${part(date.getMinutes())}`;
  });
  const [purpose, setPurpose] = useState('');
  const [bookingBusy, setBookingBusy] = useState(false);
  const [filter, setFilter] = useState('pending');
  const [decisionBusy, setDecisionBusy] = useState(null);
  const [maintenanceError, setMaintenanceError] = useState('');
  const [sidebarCollapsed, setSidebarCollapsed] = useState(() => localStorage.getItem('campusSidebarCollapsed') === 'true');

  const isAdmin = Boolean(user && (user.is_admin === true || ['admin', 'staff'].includes(String(user.role_name || '').toLowerCase())));
  const categories = useMemo(() => [...new Set(resourceList.map((resource) => resource.resource_type).filter(Boolean))].sort(), [resourceList]);
  const availableCount = resourceList.filter((resource) => ['available', 'active'].includes(String(resource.status || '').toLowerCase())).length;
  const underMaintenanceCount = resourceList.filter((resource) => String(resource.status || '').toLowerCase() === 'under_maintenance').length;
  const pendingCount = bookings.filter((booking) => String(booking.status).toLowerCase() === 'pending').length;
  const approvedCount = bookings.filter((booking) => ['confirmed', 'approved'].includes(String(booking.status).toLowerCase())).length;

  async function request(path, { method = 'GET', body, auth = true } = {}) {
    const headers = {};
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    if (auth && token) headers.Authorization = `Bearer ${token}`;
    let response;
    try {
      response = await fetch(`${apiRoot}${path}`, { method, headers, ...(body !== undefined ? { body: JSON.stringify(body) } : {}) });
    } catch {
      throw Object.assign(new Error('Cannot reach the campus service. Check that the server is running.'), { network: true });
    }
    const data = await response.json().catch(() => ({}));
    if (response.status === 401 && auth) {
      await clearSession('Your session expired. Please sign in again.');
      throw Object.assign(new Error('Your session expired. Please sign in again.'), { status: 401 });
    }
    if (!response.ok) throw Object.assign(new Error(data.error || `Request failed (${response.status}).`), { status: response.status });
    return data;
  }

  async function clearSession(notice = '') {
    const oldToken = token;
    setToken('');
    setUser(null);
    setBookings([]);
    setResourceList([]);
    setReports([]);
    localStorage.removeItem('campusBookingToken');
    localStorage.removeItem('campusBookingUser');
    setView('resources');
    if (notice) setAuthMessage({ type: 'warn', text: notice });
    if (oldToken) {
      try { await fetch(`${apiRoot}/logout`, { method: 'POST', headers: { Authorization: `Bearer ${oldToken}` } }); } catch { /* local session is already cleared */ }
    }
  }

  useEffect(() => {
    if (!token || !user) return;
    let cancelled = false;
    (async () => {
      setStatus('Connecting');
      setBookingsLoading(true);
      if (isAdmin) setMaintenanceLoading(true);
      try {
        const resources = await request('/resources', { auth: false });
        if (!cancelled) { setResourceList(Array.isArray(resources) ? resources : []); setResourceError(''); setStatus('Connected'); }
      } catch (error) {
        if (!cancelled) { setResourceError(error.message); setStatus('Offline'); }
      }
      try {
        const result = await request('/bookings');
        if (!cancelled) setBookings(Array.isArray(result) ? result : []);
      } catch (error) {
        if (!cancelled && error.status !== 401) setBookingError(error.message);
      } finally {
        if (!cancelled) setBookingsLoading(false);
      }
      if (isAdmin) {
        try {
          const result = await request('/maintenance-reports', { auth: false });
          if (!cancelled) { setReports(Array.isArray(result.reports) ? result.reports : []); setMaintenanceError(''); }
        } catch (error) {
          if (!cancelled) setMaintenanceError(error.message);
        } finally {
          if (!cancelled) setMaintenanceLoading(false);
        }
      }
    })();
    return () => { cancelled = true; };
  }, [token, user?.user_id, user?.is_admin, user?.role_name]);

  useEffect(() => {
    if (user) setView(isAdmin ? 'bookings' : 'resources');
  }, [user?.user_id, isAdmin]);

  function logActivity(type, title, detail) {
    setLogs((previous) => [{ type, title, detail, time: new Date().toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }) }, ...previous].slice(0, 20));
  }

  async function handleSignIn(event) {
    event.preventDefault();
    setAuthBusy(true);
    setAuthMessage(null);
    const form = new FormData(event.currentTarget);
    const email = String(form.get('email') || '').trim();
    try {
      const result = await request('/login', { method: 'POST', auth: false, body: { email, password: String(form.get('password') || '') } });
      localStorage.setItem('campusBookingToken', result.token);
      localStorage.setItem('campusBookingUser', JSON.stringify(result.user));
      setToken(result.token);
      setUser(result.user);
      setAuthMessage(null);
    } catch (error) {
      setAuthMessage({ type: 'bad', text: error.status === 401 ? 'Email or password is incorrect.' : error.message });
    } finally { setAuthBusy(false); }
  }

  async function handleSignUp(event) {
    event.preventDefault();
    setAuthBusy(true);
    setAuthMessage(null);
    const form = new FormData(event.currentTarget);
    const payload = {
      first_name: String(form.get('first_name') || '').trim(),
      last_name: String(form.get('last_name') || '').trim(),
      email: String(form.get('email') || '').trim(),
      password: String(form.get('password') || '')
    };
    try {
      await request('/signup', { method: 'POST', auth: false, body: payload });
      setSignInEmail(payload.email);
      setAuthView('signin');
      setAuthMessage({ type: 'ok', text: 'User registered successfully. Please sign in.' });
    } catch (error) { setAuthMessage({ type: 'bad', text: error.message }); }
    finally { setAuthBusy(false); }
  }

  async function submitBooking(event) {
    event.preventDefault();
    setBookingError('');
    setMessage(null);
    if (!selectedResource || !startTime || !endTime || new Date(startTime) >= new Date(endTime)) {
      setBookingError('Choose a resource and a valid start and end time.');
      return;
    }
    setBookingBusy(true);
    const resource = resourceList.find((item) => Number(item.resource_id) === Number(selectedResource));
    const start = toSqlDateTime(startTime);
    const end = toSqlDateTime(endTime);
    try {
      const result = await request('/bookings', { method: 'POST', body: { resource_id: Number(selectedResource), booking_date: start.slice(0, 10), start_time: start, end_time: end, purpose: purpose.trim() || null } });
      setMessage({ type: 'ok', text: `Request #${result.booking_id} submitted for staff approval.` });
      logActivity('ok', 'Booking request submitted', `#${result.booking_id} · ${resource?.resource_name || 'Campus resource'}`);
      setPurpose('');
      const refreshed = await request('/bookings');
      setBookings(Array.isArray(refreshed) ? refreshed : []);
      setView('bookings');
    } catch (error) {
      if (error.status !== 401) setBookingError(error.status === 409 ? `Time conflict: ${error.message}` : error.message);
    } finally { setBookingBusy(false); }
  }

  async function cancelBooking(booking) {
    if (!window.confirm(`Cancel booking #${booking.booking_id}? This releases the reserved time slot.`)) return;
    try {
      const result = await request(`/bookings/${booking.booking_id}`, { method: 'DELETE' });
      setMessage({ type: 'ok', text: result.message || `Booking #${booking.booking_id} cancelled.` });
      logActivity('ok', 'Booking cancelled', `#${booking.booking_id}`);
      setBookings(await request('/bookings'));
    } catch (error) { if (error.status !== 401) setBookingError(error.message); }
  }

  async function decideBooking(booking, decision) {
    setDecisionBusy(booking.booking_id);
    try {
      const result = await request(`/bookings/${booking.booking_id}/decision`, { method: 'PATCH', body: { decision } });
      setMessage({ type: 'ok', text: result.message });
      logActivity('ok', `Booking ${decision}`, `#${booking.booking_id} · ${booking.booked_by || booking.full_name || 'Campus user'}`);
      setBookings(await request('/bookings'));
    } catch (error) {
      if (error.status !== 401) setBookingError(error.message);
    } finally { setDecisionBusy(null); }
  }

  async function refreshBookings() {
    setBookingError('');
    setBookingsLoading(true);
    try { setBookings(await request('/bookings')); }
    catch (error) { if (error.status !== 401) setBookingError(error.message); }
    finally { setBookingsLoading(false); }
  }

  async function refreshResources(term = search) {
    setResourceError('');
    setStatus('Connecting');
    try {
      const resources = await request(term ? `/resources?search=${encodeURIComponent(term)}` : '/resources', { auth: false });
      setResourceList(Array.isArray(resources) ? resources : []);
      setStatus('Connected');
    } catch (error) { setResourceError(error.message); setStatus('Offline'); }
  }

  async function logout() {
    await clearSession();
    setAuthMessage(null);
    setLogs([]);
  }

  function toggleSidebar() {
    setSidebarCollapsed((collapsed) => {
      const next = !collapsed;
      localStorage.setItem('campusSidebarCollapsed', String(next));
      return next;
    });
  }

  if (!token || !user) {
    return <AuthScreen mode={authView} setMode={(next) => { setAuthView(next); setAuthMessage(null); }} busy={authBusy} message={authMessage} signInEmail={signInEmail} setSignInEmail={setSignInEmail} onSignIn={handleSignIn} onSignUp={handleSignUp} />;
  }

  const visibleResources = resourceList.filter((resource) => {
    const byCategory = !category || resource.resource_type === category;
    const resourceStatus = String(resource.status || '').toLowerCase();
    const byAvailability = !availability || (availability === 'available' ? ['available', 'active'].includes(resourceStatus) : ['under_maintenance', 'maintenance'].includes(resourceStatus));
    return byCategory && byAvailability;
  });
  const visibleBookings = isAdmin ? bookings.filter((booking) => {
    const state = String(booking.status || '').toLowerCase();
    if (filter === 'pending') return state === 'pending';
    if (filter === 'approved') return ['confirmed', 'approved'].includes(state);
    if (filter === 'closed') return ['rejected', 'cancelled'].includes(state);
    return true;
  }) : bookings;

  return (
    <>
      <header className="topbar">
        <div className="topbar-inner">
          <div className="brand"><div className="brand-mark" aria-hidden="true">SC</div><div><div className="brand-title">Smart Campus</div><div className="brand-sub">Resource &amp; lab booking</div></div></div>
          <div className="nav-right">
            <div className="identity"><span className="avatar">{initials(user.full_name)}</span><span className="identity-text"><span className="identity-name" style={{ display: 'block' }}>{user.full_name}</span><span className="identity-role" style={{ display: 'block' }}>{isAdmin ? 'Admin Staff' : String(user.role_name || 'Student').replaceAll('_', ' ')}</span></span></div>
            <button type="button" className="btn btn-ghost btn-xs" onClick={logout}>Log out</button>
          </div>
        </div>
      </header>

      <main className={`shell ${isAdmin ? 'role-admin' : 'role-user'} ${sidebarCollapsed ? 'sidebar-collapsed' : ''}`}>
        <Sidebar isAdmin={isAdmin} view={view} setView={setView} pendingCount={pendingCount} collapsed={sidebarCollapsed} onToggle={toggleSidebar} />
        <div className="app-content">
          <div className="page-intro"><div className="page-eyebrow">{isAdmin ? 'ADMIN WORKSPACE' : 'STUDENT WORKSPACE'} <span aria-hidden="true">/</span> {view === 'resources' ? (isAdmin ? 'INVENTORY' : 'DISCOVER') : view.toUpperCase()}</div><h1>{view === 'resources' ? (isAdmin ? 'Resource inventory' : 'Find campus resources') : view === 'bookings' ? (isAdmin ? 'Booking approvals' : 'My bookings') : view === 'maintenance' ? 'Maintenance reports' : 'Recent activity'}</h1><p>{view === 'resources' ? (isAdmin ? 'Explore campus equipment and resource availability.' : 'Discover labs and equipment, then request a time that works for you.') : view === 'bookings' ? (isAdmin ? 'Review requests and keep campus bookings moving.' : 'Track your requests and see their latest status.') : view === 'maintenance' ? 'Review inspection and service records for campus equipment.' : 'A timeline of actions from your current session.'}</p></div>
          <section className="kpi-grid" aria-label="Campus summary">
            <Kpi label="Resources" value={resourceList.length} caption="Registered on campus" />
            <Kpi label="Available" value={availableCount} caption="Open for booking requests" />
            <Kpi label={isAdmin ? 'Pending approvals' : 'Under maintenance'} value={isAdmin ? pendingCount : underMaintenanceCount} caption={isAdmin ? 'Waiting for staff review' : 'Temporarily offline'} />
            <Kpi label={isAdmin ? 'Approved bookings' : 'My active bookings'} value={isAdmin ? approvedCount : pendingCount + approvedCount} caption={isAdmin ? 'Across campus' : 'Pending or approved'} />
          </section>

          {message && <div className={`alert ${message.type}`} role="status">{message.text}<button type="button" className="btn-link" onClick={() => setMessage(null)} aria-label="Dismiss message">Dismiss</button></div>}
          {view === 'resources' && <div className={`workspace ${isAdmin ? 'single' : ''}`}>
            <ResourceInventory resources={visibleResources} categories={categories} search={search} setSearch={setSearch} onSearch={() => refreshResources(search.trim())} onReset={() => { setSearch(''); setCategory(''); setAvailability(''); refreshResources(''); }} category={category} setCategory={setCategory} availability={availability} setAvailability={setAvailability} error={resourceError} status={status} onRefresh={() => refreshResources('')} onPick={(id) => setSelectedResource(String(id))} selectedId={selectedResource} isAdmin={isAdmin} />
            {!isAdmin && <BookingForm user={user} resources={resourceList} selectedResource={selectedResource} setSelectedResource={setSelectedResource} startTime={startTime} setStartTime={setStartTime} endTime={endTime} setEndTime={setEndTime} purpose={purpose} setPurpose={setPurpose} busy={bookingBusy} onSubmit={submitBooking} error={bookingError} clearError={() => setBookingError('')} />}
          </div>}

          {view === 'bookings' && <BookingsPanel isAdmin={isAdmin} bookings={visibleBookings} allBookings={bookings} loading={bookingsLoading} filter={filter} setFilter={setFilter} onRefresh={refreshBookings} onCancel={cancelBooking} onDecision={decideBooking} decisionBusy={decisionBusy} error={bookingError} />}
          {view === 'maintenance' && isAdmin && <MaintenancePanel reports={reports} loading={maintenanceLoading} error={maintenanceError} onRefresh={async () => {
            setMaintenanceLoading(true);
            setMaintenanceError('');
            try { const data = await request('/maintenance-reports', { auth: false }); setReports(Array.isArray(data.reports) ? data.reports : []); }
            catch (error) { setMaintenanceError(error.message); }
            finally { setMaintenanceLoading(false); }
          }} />}
          {view === 'activity' && <ActivityPanel logs={logs} onClear={() => setLogs([])} />}
        </div>
      </main>
    </>
  );
}

function AuthScreen({ mode, setMode, busy, message, signInEmail, setSignInEmail, onSignIn, onSignUp }) {
  return <>
    <header className="topbar"><div className="topbar-inner"><div className="brand"><div className="brand-mark">SC</div><div><div className="brand-title">Smart Campus</div><div className="brand-sub">Resource &amp; lab booking</div></div></div><span className="status-pill"><span className="dot"/>Campus booking portal</span></div></header>
    <main className="login-view"><section className="login-card" aria-labelledby="authTitle">
      <div className="brand-mark" style={{ marginBottom: 18 }}>SC</div>
      <h1 id="authTitle">{mode === 'signin' ? 'Welcome back' : 'Create your account'}</h1>
      <p className="lead">{mode === 'signin' ? 'Sign in to find and book campus resources.' : 'Set up your account to request campus resources.'}</p>
      {message && <div className={`alert ${message.type}`} role={message.type === 'bad' ? 'alert' : 'status'}>{message.text}</div>}
      {mode === 'signin' ? <form onSubmit={onSignIn}>
        <div className="field"><label htmlFor="loginEmail">Email</label><input id="loginEmail" name="email" type="email" autoComplete="email" value={signInEmail} onChange={(event) => setSignInEmail(event.target.value)} required /></div>
        <div className="field"><label htmlFor="loginPassword">Password</label><input id="loginPassword" name="password" type="password" autoComplete="current-password" required /></div>
        <button className="btn btn-primary" type="submit" disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
        <p className="auth-footer">New here? <button type="button" onClick={() => setMode('signup')}>Create an account</button></p>
      </form> : <form onSubmit={onSignUp}>
        <div className="name-row"><div className="field"><label htmlFor="firstName">First name</label><input id="firstName" name="first_name" autoComplete="given-name" maxLength="50" required /></div><div className="field"><label htmlFor="lastName">Last name</label><input id="lastName" name="last_name" autoComplete="family-name" maxLength="50" required /></div></div>
        <div className="field"><label htmlFor="signupEmail">Email</label><input id="signupEmail" name="email" type="email" autoComplete="email" required /></div>
        <div className="field"><label htmlFor="signupPassword">Password</label><input id="signupPassword" name="password" type="password" autoComplete="new-password" minLength="8" required /><p className="field-hint">At least 8 characters.</p></div>
        <button className="btn btn-primary" type="submit" disabled={busy}>{busy ? 'Creating account…' : 'Create account'}</button>
        <p className="auth-footer">Already have an account? <button type="button" onClick={() => setMode('signin')}>Sign in</button></p>
      </form>}
    </section></main>
  </>;
}

function Sidebar({ isAdmin, view, setView, pendingCount, collapsed, onToggle }) {
  const links = [
    { key: 'resources', label: isAdmin ? 'Resource inventory' : 'Browse resources', icon: 'resources' },
    { key: 'bookings', label: isAdmin ? 'Approvals' : 'My Bookings', icon: 'bookings', count: isAdmin ? pendingCount : null },
    ...(isAdmin ? [{ key: 'maintenance', label: 'Maintenance', icon: 'maintenance' }] : []),
    { key: 'activity', label: 'Activity', icon: 'activity' }
  ];
  return <aside className={`sidebar ${collapsed ? 'collapsed' : ''}`} aria-label="Campus workspace navigation"><div className="sidebar-top"><div className="sidebar-heading">Workspace</div><button type="button" className="sidebar-toggle" onClick={onToggle} aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'} aria-expanded={!collapsed} title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 6h16M4 12h16M4 18h16"/><path className="toggle-arrow" d={collapsed ? 'm9 7 5 5-5 5' : 'm15 7-5 5 5 5'}/></svg></button></div><nav className="sidebar-nav" aria-label="Main navigation">
    {links.map((link) => <button key={link.key} type="button" className="sidebar-link" title={collapsed ? link.label : undefined} aria-current={view === link.key ? 'page' : undefined} onClick={() => setView(link.key)}><span className="sidebar-icon"><Icon name={link.icon}/></span><span className="sidebar-label">{link.label}</span>{link.count > 0 && <span className="sidebar-count">{link.count}</span>}</button>)}
  </nav><p className="sidebar-note">Campus resources and bookings in one place.</p></aside>;
}

function Kpi({ label, value, caption }) {
  return <div className="kpi-card"><div className="kpi-label">{label}</div><div className="kpi-val">{value}</div><div className="kpi-sub">{caption}</div></div>;
}

function ResourceInventory({ resources, categories, search, setSearch, onSearch, onReset, category, setCategory, availability, setAvailability, error, status, onRefresh, onPick, selectedId, isAdmin }) {
  return <section className="panel" aria-labelledby="resourcesTitle">
    <div className="panel-head"><div><h2 id="resourcesTitle">{isAdmin ? 'Resource inventory' : 'Browse resources'}</h2><p>{isAdmin ? 'Read-only view of campus resources and their status.' : 'Search campus labs and equipment, then choose one to book.'}</p></div><button type="button" className="btn btn-ghost btn-xs" onClick={onRefresh}>Refresh</button></div>
    <div className="panel-body"><div className="toolbar"><form className="toolbar-row" onSubmit={(event) => { event.preventDefault(); onSearch(); }}>
      <div><label className="sr-only" htmlFor="resourceSearch">Search resources</label><input id="resourceSearch" type="search" placeholder="Search by name, code, building or room" value={search} onChange={(event) => setSearch(event.target.value)} /></div>
      <div><label className="sr-only" htmlFor="resourceCategory">Category</label><select id="resourceCategory" value={category} onChange={(event) => setCategory(event.target.value)}><option value="">All categories</option>{categories.map((item) => <option key={item} value={item}>{item}</option>)}</select></div>
      <button type="submit" className="btn btn-primary" id="searchBtn">Search</button><button type="button" className="btn btn-ghost" onClick={onReset}>Reset</button>
    </form>
      <div className="toolbar-meta"><div className="segmented" role="group" aria-label="Filter by availability">{[['', 'All'], ['available', 'Available'], ['under_maintenance', 'Under maintenance']].map(([value, label]) => <button type="button" key={value || 'all'} className="seg-btn" aria-pressed={availability === value} onClick={() => setAvailability(value)}>{label}</button>)}</div><span className="result-count">Showing {resources.length}</span></div>
    </div>
    {error && <div className="alert bad" role="alert">{error}</div>}
    <div className="table-wrap"><table className="stack" aria-label="Campus resources"><thead><tr><th>Resource</th><th>Category</th><th>Location</th><th>Capacity</th><th>Status</th>{!isAdmin && <th className="right">Action</th>}</tr></thead><tbody>
      {resources.length ? resources.map((resource) => <tr key={resource.resource_id} className={Number(selectedId) === Number(resource.resource_id) ? 'selected' : ''}>
        <td data-label="Resource"><div className="res-name">{resource.resource_name}</div><span className="code-tag">{resource.resource_code}</span>{resource.description && <div className="res-desc">{resource.description}</div>}</td>
        <td data-label="Category"><span className="res-meta">{resource.resource_type || '—'}</span></td>
        <td data-label="Location"><span className="res-meta">{[resource.building_name, resource.floor_number != null ? `Floor ${resource.floor_number}` : '', resource.room_number ? `Room ${resource.room_number}` : ''].filter(Boolean).join(' · ') || '—'}</span></td>
        <td data-label="Capacity">{resource.capacity ?? '—'}</td><td data-label="Status"><ResourceBadge status={resource.status}/></td>
        {!isAdmin && <td data-label="Action" className="right cell-actions"><button className={`btn ${Number(selectedId) === Number(resource.resource_id) ? 'btn-primary' : 'btn-ghost'} btn-xs`} type="button" onClick={() => onPick(resource.resource_id)}>{Number(selectedId) === Number(resource.resource_id) ? 'Selected' : 'Book this'}</button></td>}
      </tr>) : <tr><td className="state-cell" colSpan={isAdmin ? 5 : 6}>{status === 'Offline' ? 'Resource inventory is unavailable. Check the server and retry.' : status === 'Connecting' ? 'Loading campus resources…' : 'No resources match these filters.'}</td></tr>}
    </tbody></table></div>
    <p className="field-hint" style={{ marginTop: 10 }}>Availability reflects each resource’s current status. Time conflicts are checked when a request is submitted.</p>
    </div>
  </section>;
}

function ResourceBadge({ status }) {
  const key = String(status || '').toLowerCase();
  const tone = key === 'available' || key === 'active' ? 'ok' : ['under_maintenance', 'maintenance'].includes(key) ? 'warn' : 'neutral';
  const label = key === 'under_maintenance' ? 'Under maintenance' : key.replaceAll('_', ' ') || 'Unknown';
  return <span className={`badge ${tone}`}>{label}</span>;
}

function BookingForm({ user, resources, selectedResource, setSelectedResource, startTime, setStartTime, endTime, setEndTime, purpose, setPurpose, busy, onSubmit, error, clearError }) {
  const usableResources = resources.filter((resource) => ['available', 'active'].includes(String(resource.status || '').toLowerCase()));
  function extend(hours) {
    if (!startTime) return;
    const end = new Date(startTime);
    end.setHours(end.getHours() + hours);
    const pad = (value) => String(value).padStart(2, '0');
    setEndTime(`${end.getFullYear()}-${pad(end.getMonth() + 1)}-${pad(end.getDate())}T${pad(end.getHours())}:${pad(end.getMinutes())}`);
  }
  return <section className="side-sticky" id="bookingRequestWrap"><div className="panel" id="bookingRequestPanel"><div className="panel-head"><div><h2>Request a booking</h2><p>Staff review every request before it is confirmed.</p></div></div><div className="panel-body">
    <form onSubmit={onSubmit}>
      <div className="field"><span className="field-label">Booking as</span><div className="readonly-box"><span className="avatar">{initials(user.full_name)}</span><span><strong className="readonly-name" style={{ display: 'block' }}>{user.full_name}</strong><span className="readonly-sub">{user.email}</span></span></div></div>
      <div className="field"><label htmlFor="resourceId">Resource <span className="req">*</span></label><select id="resourceId" value={selectedResource} onChange={(event) => { setSelectedResource(event.target.value); clearError(); }} required><option value="">Select a resource…</option>{usableResources.map((resource) => <option key={resource.resource_id} value={resource.resource_id}>{resource.resource_name} — {resource.resource_code}</option>)}</select></div>
      <div className="grid-2"><div className="field"><label htmlFor="startTime">Start <span className="req">*</span></label><input id="startTime" type="datetime-local" value={startTime} onChange={(event) => setStartTime(event.target.value)} required /></div><div className="field"><label htmlFor="endTime">End <span className="req">*</span></label><input id="endTime" type="datetime-local" value={endTime} onChange={(event) => setEndTime(event.target.value)} required /></div></div>
      <div className="chip-row"><span>Set end time:</span>{[1, 2, 3].map((hours) => <button key={hours} type="button" className="chip" onClick={() => extend(hours)}>+{hours} hr{hours > 1 ? 's' : ''}</button>)}</div>
      <div className="field"><label htmlFor="purpose">Purpose <span className="opt">(optional)</span></label><textarea id="purpose" rows="3" maxLength="255" value={purpose} onChange={(event) => setPurpose(event.target.value)} placeholder="e.g. Course project, lab session, prototype print"/><div className="res-meta" style={{ textAlign: 'right' }}>{purpose.length} / 255</div></div>
      <button className="btn btn-primary" type="submit" disabled={busy || !usableResources.length} style={{ width: '100%', minHeight: 40 }}>{busy ? 'Submitting…' : 'Submit request'}</button>
    </form>
    {error && <div className="alert bad" role="alert">{error}</div>}
  </div></div></section>;
}

function BookingsPanel({ isAdmin, bookings, allBookings, loading, filter, setFilter, onRefresh, onCancel, onDecision, decisionBusy, error }) {
  const counts = {
    all: allBookings.length,
    pending: allBookings.filter((booking) => String(booking.status).toLowerCase() === 'pending').length,
    approved: allBookings.filter((booking) => ['confirmed', 'approved'].includes(String(booking.status).toLowerCase())).length,
    closed: allBookings.filter((booking) => ['rejected', 'cancelled'].includes(String(booking.status).toLowerCase())).length
  };
  return <section className="panel" id="bookingsPanel"><div className="panel-head"><div><h2>{isAdmin ? 'All Campus Bookings' : 'My Bookings'}</h2><p>{isAdmin ? 'Campus-wide requests with pending approvals at the top.' : 'Your requests and their current status.'}</p></div><button type="button" className="btn btn-ghost btn-xs" onClick={onRefresh}>Refresh</button></div><div className="panel-body">
    {error && <div className="alert bad" role="alert">{error}</div>}
    {isAdmin && <div className="segmented" role="group" aria-label="Filter bookings by status" style={{ marginBottom: 14 }}>{[['all', 'All'], ['pending', 'Pending'], ['approved', 'Approved'], ['closed', 'Rejected / cancelled']].map(([key, label]) => <button type="button" key={key} className="seg-btn" aria-pressed={filter === key} onClick={() => setFilter(key)}>{label} <span className="count-pill">{counts[key]}</span></button>)}</div>}
    {isAdmin && counts.pending > 0 && <div className="queue-banner"><strong>{counts.pending} {counts.pending === 1 ? 'request is' : 'requests are'} waiting for your decision.</strong></div>}
    <div className="table-wrap"><table className="stack" aria-label={isAdmin ? 'All campus bookings' : 'My bookings'}><thead><tr>{isAdmin ? <><th>Booking</th><th>Requested by</th><th>Resource</th><th>When</th><th>Purpose</th><th>Status</th><th className="right">Actions</th></> : <><th>Booking</th><th>Resource</th><th>When</th><th>Status</th><th className="right">Action</th></>}</tr></thead><tbody>
      {loading ? <tr><td className="state-cell" colSpan={isAdmin ? 7 : 5}>Loading bookings…</td></tr> : bookings.length ? bookings.map((booking) => {
        const pending = String(booking.status).toLowerCase() === 'pending';
        return <tr key={booking.booking_id} className={pending ? 'row-pending' : ''}>
          <td data-label="Booking"><span className="id-cell">#{booking.booking_id}</span></td>
          {isAdmin && <td data-label="Requested by"><strong>{booking.booked_by || booking.full_name || 'Unknown user'}</strong><div className="res-meta">{booking.user_email}</div></td>}
          <td data-label="Resource"><div className="res-name">{booking.resource_name || 'Resource unavailable'}</div>{booking.resource_code && <span className="code-tag">{booking.resource_code}</span>}{!isAdmin && booking.purpose && <div className="res-desc">{booking.purpose}</div>}</td>
          <td data-label="When"><div className="when-date">{dateWindow(booking.start_time, booking.end_time)}</div></td>
          {isAdmin && <td data-label="Purpose"><span className="res-meta">{booking.purpose || '—'}</span></td>}
          <td data-label="Status"><StatusBadge status={booking.status}/></td>
          <td data-label={isAdmin ? 'Actions' : 'Action'} className="right cell-actions">{isAdmin ? pending ? <div className="row-actions"><button type="button" className="btn btn-approve btn-xs" disabled={decisionBusy === booking.booking_id} onClick={() => onDecision(booking, 'approved')}>Approve</button><button type="button" className="btn btn-danger-outline btn-xs" disabled={decisionBusy === booking.booking_id} onClick={() => onDecision(booking, 'rejected')}>Reject</button></div> : <span className="res-meta">No action needed</span> : ['pending', 'confirmed'].includes(String(booking.status).toLowerCase()) ? <button type="button" className="btn btn-danger-outline btn-xs" onClick={() => onCancel(booking)}>Cancel</button> : <span className="res-meta">—</span>}</td>
        </tr>;
      }) : <tr><td className="state-cell" colSpan={isAdmin ? 7 : 5}>{allBookings.length ? 'No bookings match this filter.' : isAdmin ? 'No campus bookings yet.' : 'You have not booked anything yet. Browse resources to get started.'}</td></tr>}
    </tbody></table></div>
  </div></section>;
}

function MaintenancePanel({ reports, loading, error, onRefresh }) {
  return <section className="panel"><div className="panel-head"><div><h2>Maintenance reports</h2><p>Inspection and repair records for campus equipment.</p></div><button className="btn btn-ghost btn-xs" type="button" onClick={onRefresh}>Refresh</button></div><div className="panel-body">
    {error && <div className="alert warn">Maintenance reports are unavailable: {error}</div>}
    <div className="table-wrap"><table className="stack" aria-label="Maintenance reports"><thead><tr><th>Report</th><th>Equipment</th><th>Issue</th><th>Severity</th><th>Status</th><th>Inspected</th><th>Technician</th></tr></thead><tbody>
      {loading ? <tr><td className="state-cell" colSpan="7">Loading maintenance reports…</td></tr> : reports.length ? reports.map((report) => <tr key={report.report_id}><td data-label="Report"><span className="id-cell">{report.report_id}</span></td><td data-label="Equipment"><div className="res-name">{report.resource_name || report.equipment_name}</div><span className="code-tag">{report.resource_code}</span></td><td data-label="Issue">{report.issue_summary || '—'}</td><td data-label="Severity"><span className={`badge ${['high', 'critical'].includes(String(report.severity).toLowerCase()) ? 'bad' : String(report.severity).toLowerCase() === 'medium' ? 'warn' : 'neutral'}`}>{report.severity || 'Unspecified'}</span></td><td data-label="Status"><span className="badge neutral">{report.status || 'Unknown'}</span></td><td data-label="Inspected">{report.inspection_date ? dateTime(report.inspection_date) : '—'}</td><td data-label="Technician">{typeof report.technician === 'string' ? report.technician : report.technician?.name || '—'}</td></tr>) : <tr><td className="state-cell" colSpan="7">{error ? 'Reports could not be loaded.' : 'No maintenance reports found.'}</td></tr>}
    </tbody></table></div>
  </div></section>;
}

function ActivityPanel({ logs, onClear }) {
  return <section className="panel"><div className="panel-head"><div><h2>Activity</h2><p>Recent actions taken in this browser session.</p></div><button className="btn btn-ghost btn-xs" type="button" onClick={onClear}>Clear</button></div><div className="panel-body"><div className="feed-list">{logs.length ? logs.map((item, index) => <div className={`feed-item ${item.type}`} key={`${item.time}-${index}`}><div><strong>{item.title}</strong><div className="res-meta">{item.detail}</div></div><span className="mono muted">{item.time}</span></div>) : <p className="res-meta">No activity yet in this session.</p>}</div></div></section>;
}

createRoot(document.getElementById('root')).render(<React.StrictMode><App /></React.StrictMode>);
