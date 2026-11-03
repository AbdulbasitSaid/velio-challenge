/* @ds-bundle: {"format":4,"namespace":"Velio","components":[{"name":"Button"},{"name":"SpotsBadge"},{"name":"LivePill"},{"name":"Avatar"},{"name":"AvatarStack"},{"name":"Chip"},{"name":"TextField"},{"name":"Segmented"},{"name":"ActivityCard"},{"name":"DetailRows"},{"name":"BookingRef"},{"name":"MemberRow"},{"name":"AttendanceRow"},{"name":"NextSteps"},{"name":"PlanCard"},{"name":"Banner"},{"name":"Toast"},{"name":"ConfirmDialog"},{"name":"BottomSheet"},{"name":"EmptyState"},{"name":"Skeleton"},{"name":"AppHeader"},{"name":"AppBar"},{"name":"MapView"},{"name":"LocationBlock"},{"name":"LocationPicker"},{"name":"CommunityMap"},{"name":"PhotoArt"},{"name":"Icon"}]} */
(function () {
  var React = window.React;
  var h = React.createElement;
  var Fragment = React.Fragment;

  function cx() {
    var out = [];
    for (var i = 0; i < arguments.length; i++) if (arguments[i]) out.push(arguments[i]);
    return out.join(' ');
  }

  // Line icons, 24px grid, 1.75 stroke. Drawn for Velio; no brand icon set was available.
  var PATHS = {
    calendar: 'M4 6.5h16v13H4zM4 10h16M8 4v4M16 4v4',
    pin: 'M12 21s-6.5-5.6-6.5-11a6.5 6.5 0 0 1 13 0C18.5 15.4 12 21 12 21zM12 12.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z',
    price: 'M4 12.5V5h7.5l8.5 8.5-7.5 7.5zM8.5 9h.01',
    host: 'M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4.5 20.5c1.2-3.6 4-5.5 7.5-5.5s6.3 1.9 7.5 5.5',
    people: 'M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20c.9-3.2 3.3-5 6.5-5s5.6 1.8 6.5 5M16 4.5a3.2 3.2 0 0 1 0 6.2M18 15.3c1.7.6 2.9 2.2 3.5 4.7',
    directions: 'M12 2.8l9.2 9.2-9.2 9.2L2.8 12zM9 14.5V12a1.5 1.5 0 0 1 1.5-1.5H15M13 8.5l2 2-2 2',
    check: 'M5 12.5l4.5 4.5L19 7.5',
    close: 'M6 6l12 12M18 6L6 18',
    search: 'M10.5 17.5a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM15.5 15.5L20.5 20.5',
    share: 'M12 15V3.5M7.5 8L12 3.5 16.5 8M5 12.5V20h14v-7.5',
    copy: 'M8.5 8.5h11v11h-11zM15.5 8.5v-4h-11v11h4',
    chevron: 'M9.5 5.5L16 12l-6.5 6.5',
    back: 'M14.5 5.5L8 12l6.5 6.5',
    plus: 'M12 5v14M5 12h14',
    minus: 'M5 12h14',
    offline: 'M3 3l18 18M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 4.5-2.4M19 13a10 10 0 0 0-2.3-1.6M2 9.5A14 14 0 0 1 7 6.6M22 9.5A14 14 0 0 0 11 6M12 20h.01',
    alert: 'M12 3.5l9.5 16.5h-19zM12 10v4.5M12 17.5h.01',
    info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5.5M12 7.5h.01',
    lock: 'M6 10.5h12v10H6zM8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3',
    map: 'M3.5 6.5L9 4l6 2.5L20.5 4v13.5L15 20l-6-2.5L3.5 20zM9 4v13.5M15 6.5V20',
    list: 'M8.5 6.5h12M8.5 12h12M8.5 17.5h12M4 6.5h.01M4 12h.01M4 17.5h.01',
    flag: 'M5 21V4M5 4.5h12l-2.5 4 2.5 4H5',
    clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7.5V12l3 2',
    ticket: 'M3.5 7.5h17v3a2 2 0 0 0 0 4v3h-17v-3a2 2 0 0 0 0-4zM14.5 7.5v10',
    refresh: 'M20 11.5A8 8 0 0 0 5.5 7M4 12.5A8 8 0 0 0 18.5 17M5 3.5V7h3.5M19 20.5V17h-3.5',
    menu: 'M4 7h16M4 12h16M4 17h16',
    target: 'M12 19.5a7.5 7.5 0 1 0 0-15 7.5 7.5 0 0 0 0 15zM12 2v3M12 19v3M2 12h3M19 12h3M12 13.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3z',
    phone: 'M7 2.5h10v19H7zM11 18.5h2',
    sparkle: 'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z',
    arrow: 'M4.5 12h15M13.5 6l6 6-6 6'
  };

  function Icon(p) {
    return h('svg', { className: cx('vl-icon', p.className), viewBox: '0 0 24 24', 'aria-hidden': p.label ? undefined : 'true', role: p.label ? 'img' : undefined, 'aria-label': p.label },
      h('path', { d: PATHS[p.name] || PATHS.info }));
  }

  function Button(p) {
    var variant = p.variant || 'primary';
    var tag = p.href ? 'a' : 'button';
    var props = {
      className: cx('vl-btn', 'vl-btn-' + variant, p.block && 'vl-btn-block', p.small && 'vl-btn-sm', p.loading && 'is-loading', p.className),
      disabled: tag === 'button' ? (p.disabled || p.loading) : undefined,
      'aria-busy': p.loading ? 'true' : undefined,
      onClick: p.onClick, href: p.href, type: tag === 'button' ? (p.type || 'button') : undefined, id: p.id
    };
    return h(tag, props,
      p.loading ? h('span', { className: 'vl-spinner', 'aria-hidden': 'true' }) : (p.icon ? h(Icon, { name: p.icon }) : null),
      p.children);
  }

  function SpotsBadge(p) {
    var spots = p.spots == null ? 0 : p.spots;
    var state = p.state || 'live';
    var cls = 'vl-spots', label, dot = true;
    if (state === 'stale') { cls += ' vl-spots-stale'; label = p.label || 'Reconnecting…'; dot = false; }
    else if (spots <= 0) { cls += ' vl-spots-soldout'; label = 'Sold out'; dot = false; }
    else if (spots <= 2) { cls += ' vl-spots-last'; label = spots === 1 ? 'Last spot' : 'Last 2 spots'; dot = false; }
    else { label = spots + ' spots left'; if (state === 'changed') cls += ' vl-spots-changed'; }
    return h('span', { className: cx(cls, p.className), role: 'status', 'aria-live': 'polite' },
      dot ? h('span', { className: 'vl-dot', 'aria-hidden': 'true' }) : null, label);
  }

  function LivePill(p) {
    var s = p.status || 'live';
    var text = s === 'live' ? 'Live' : s === 'reconnecting' ? 'Reconnecting…' : ('Offline' + (p.minutes != null ? ' · updated ' + p.minutes + ' min ago' : ''));
    return h('span', { className: cx('vl-pill', s !== 'live' && 'vl-pill-' + s), role: 'status' },
      s === 'live' ? h('span', { className: 'vl-dot vl-dot-pulse', 'aria-hidden': 'true' }) : (s === 'offline' ? h(Icon, { name: 'offline', className: '' }) : h('span', { className: 'vl-spinner', 'aria-hidden': 'true', style: { width: 10, height: 10 } })),
      text);
  }

  var AVATAR_TOKENS = ['--lime', '--sky', '--sun', '--lilac', '--peach'];
  function avatarIndex(seed) {
    var s = String(seed || ''), x = 5381;
    for (var i = 0; i < s.length; i++) x = ((x << 5) + x + s.charCodeAt(i)) >>> 0;
    return x % 5;
  }
  function initials(name) {
    var parts = String(name || '?').replace(/\./g, '').trim().split(/\s+/);
    return ((parts[0] || '?')[0] + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
  }
  function Avatar(p) {
    var size = p.size || 40;
    var bg = p.plus ? 'var(--surface)' : 'var(' + AVATAR_TOKENS[avatarIndex(p.seed || p.name)] + ')';
    return h('span', { className: 'vl-avatar', style: { width: size, height: size, background: bg, fontSize: Math.round(size * 0.36) }, 'aria-hidden': p.decorative ? 'true' : undefined, title: p.decorative ? undefined : p.name },
      p.plus ? '+' + p.plus : initials(p.name));
  }
  function AvatarStack(p) {
    var people = p.people || [];
    var max = p.max || 3;
    var shown = people.slice(0, max);
    var extra = (p.total || people.length) - shown.length;
    return h('div', { className: 'vl-stack' },
      h('div', { className: 'vl-stack-faces', 'aria-hidden': 'true' },
        shown.map(function (n, i) { return h(Avatar, { key: i, name: n, size: p.size || 34, decorative: true }); }),
        extra > 0 ? h(Avatar, { plus: extra, size: p.size || 34, decorative: true }) : null),
      p.label === false ? null : h('span', { className: 'vl-stack-label' }, p.label || defaultGoing(shown, extra)));
  }
  function defaultGoing(shown, extra) {
    if (!shown.length) return 'Be the first to book';
    if (shown.length === 1 && extra <= 0) return shown[0] + ' is going';
    var names = shown.slice(0, 2).join(', ');
    var rest = extra + Math.max(0, shown.length - 2);
    return rest > 0 ? names + ' and ' + rest + ' other' + (rest === 1 ? '' : 's') + ' are going' : shown.join(' and ') + ' are going';
  }

  function Chip(p) {
    return h('span', { className: cx('vl-chip', p.tone && p.tone !== 'neutral' && 'vl-chip-' + p.tone, p.className) },
      p.icon ? h(Icon, { name: p.icon, className: '' }) : null, p.children);
  }

  function TextField(p) {
    var id = p.id || ('f-' + String(p.label || 'field').toLowerCase().replace(/[^a-z0-9]+/g, '-'));
    var describedBy = p.error ? id + '-err' : (p.help ? id + '-help' : undefined);
    var control = h(p.multiline ? 'textarea' : 'input', {
      id: id, type: p.multiline ? undefined : (p.type || 'text'), defaultValue: p.value, placeholder: p.placeholder,
      'aria-invalid': p.error ? 'true' : undefined, 'aria-describedby': describedBy, maxLength: p.maxLength,
      inputMode: p.inputMode, autoComplete: p.autoComplete, readOnly: p.readOnly, disabled: p.disabled
    });
    return h('div', { className: cx('vl-field', p.code && 'vl-field-code', p.search && 'vl-field-search', p.error && 'has-error', p.className) },
      p.label ? h('label', { htmlFor: id }, p.label) : null,
      p.search ? h('div', { style: { position: 'relative' } }, h(Icon, { name: 'search' }), control) : control,
      p.error ? h('span', { className: 'vl-field-error', id: id + '-err' }, h(Icon, { name: 'alert' }), p.error) : null,
      !p.error && (p.help || p.count != null) ? h('span', { className: 'vl-field-help', id: id + '-help' }, h('span', null, p.help || ''), p.count != null ? h('span', null, p.count + ' / ' + p.maxLength) : null) : null);
  }

  function Segmented(p) {
    return h('div', { className: 'vl-seg', role: 'group', 'aria-label': p.label },
      (p.options || []).map(function (o) {
        var val = typeof o === 'string' ? o : o.value;
        return h('button', { key: val, type: 'button', 'aria-pressed': p.value === val ? 'true' : 'false', onClick: p.onChange ? function () { p.onChange(val); } : undefined },
          o.icon ? h(Icon, { name: o.icon, className: '' }) : null, typeof o === 'string' ? o : o.label);
      }));
  }

  // Representative photo art: a duotone landscape. Real activity photos replace it.
  var SCENES = {
    lake: { sky: 'var(--sun)', far: 'var(--peach)', near: 'var(--forest)', water: 'var(--sky)' },
    savanna: { sky: 'var(--peach)', far: 'var(--sun)', near: 'var(--forest)', water: 'var(--lime)' },
    city: { sky: 'var(--lilac)', far: 'var(--sky)', near: 'var(--forest)', water: 'var(--lime)' },
    coast: { sky: 'var(--sky)', far: 'var(--lime)', near: 'var(--forest)', water: 'var(--info)' }
  };
  function PhotoArt(p) {
    var s = SCENES[p.scene] || SCENES.lake;
    return h('svg', { viewBox: '0 0 320 200', preserveAspectRatio: 'xMidYMid slice', role: 'img', 'aria-label': p.alt || 'Activity photo' },
      h('rect', { width: 320, height: 200, style: { fill: s.sky } }),
      h('circle', { cx: 232, cy: 78, r: 30, style: { fill: 'var(--surface)', opacity: 0.85 } }),
      h('path', { d: 'M0 120 L60 84 L110 108 L170 70 L240 112 L320 92 L320 200 L0 200Z', style: { fill: s.far } }),
      h('path', { d: 'M0 140 L320 132 L320 200 L0 200Z', style: { fill: s.water } }),
      h('path', { d: 'M0 150 C60 140 90 160 150 152 C210 144 260 162 320 150 L320 200 L0 200Z', style: { fill: s.near } }),
      h('path', { d: 'M150 132 l14 -6 l14 6z', style: { fill: s.near } }));
  }

  function DetailRows(p) {
    return h('ul', { className: 'vl-details' }, (p.rows || []).map(function (r, i) {
      return h('li', { key: i }, h(Icon, { name: r.icon || 'info' }),
        h('span', null, r.label ? h('span', { className: 'vl-details-label' }, r.label) : null, h('span', { className: 'vl-details-value' }, r.value), r.sub ? h('span', { className: 'vl-details-label' }, r.sub) : null));
    }));
  }

  function ActivityCard(p) {
    return h('article', { className: cx('vl-activity', p.compact && 'vl-activity-compact') },
      h('div', { className: 'vl-activity-photo' }, h(PhotoArt, { scene: p.scene, alt: p.title }),
        p.community ? h(Chip, { tone: 'outline' }, p.community) : null,
        p.spots != null ? h(SpotsBadge, { spots: p.spots, state: p.spotsState }) : null),
      h('div', { className: 'vl-activity-body' },
        p.lead ? h('span', { style: { color: 'var(--forest)', fontWeight: 700 } }, p.lead) : null,
        h('h3', { className: 'vl-activity-title' }, p.title),
        p.compact ? h('span', { style: { color: 'var(--muted)', fontSize: 14 } }, [p.date, p.place].filter(Boolean).join(' · ')) :
          h(DetailRows, { rows: [
            { icon: 'calendar', value: p.date, sub: p.zone },
            { icon: 'pin', value: p.place, sub: p.address },
            { icon: 'price', value: p.price ? p.price + ' · pay the host on the day' : null },
            { icon: 'host', value: p.host ? 'Hosted by ' + p.host : null }
          ].filter(function (r) { return r.value; }) }),
        p.going ? h(AvatarStack, { people: p.going, total: p.goingTotal }) : null,
        p.children));
  }

  function BookingRef(p) {
    return h('div', { className: 'vl-ref' }, h('span', { className: 'vl-ref-label' }, p.label || 'Booking ref'), h('span', { className: 'vl-ref-code' }, p.code || 'VLO-48213'));
  }

  var SOURCE_TONE = { direct: 'neutral', vouch: 'lime', public: 'sky' };
  var STATUS_TONE = { created: 'neutral', opened: 'sky', claimed: 'lime' };
  function MemberRow(p) {
    return h('div', { className: cx('vl-listrow', p.removed && 'is-removed') },
      p.pending ? h('span', { className: 'vl-avatar', style: { width: 40, height: 40, background: 'var(--line)', color: 'var(--muted)' } }, h(Icon, { name: 'ticket' })) : h(Avatar, { name: p.name, decorative: true }),
      h('div', { className: 'vl-listrow-main' },
        h('span', { className: 'vl-listrow-name' }, p.name, p.you ? ' (you)' : ''),
        h('span', { className: 'vl-listrow-meta' }, p.removed ? 'The host removed this booking' : p.meta)),
      h('div', { className: 'vl-listrow-end' },
        p.status ? h(Chip, { tone: STATUS_TONE[p.status] }, p.status.charAt(0).toUpperCase() + p.status.slice(1)) : null,
        p.source ? h(Chip, { tone: SOURCE_TONE[p.source] }, p.sourceLabel || (p.source === 'direct' ? 'Direct' : p.source === 'public' ? 'Public link' : 'Vouch')) : null));
  }

  function AttendanceRow(p) {
    var mode = p.mode || 'before';
    return h('div', { className: cx('vl-listrow', p.isNew && 'is-new', p.removed && 'is-removed') },
      h(Avatar, { name: p.name, decorative: true }),
      h('div', { className: 'vl-listrow-main' },
        h('span', { className: 'vl-listrow-name' }, p.name),
        h('span', { className: 'vl-listrow-meta' }, [p.bookingRef, p.time].filter(Boolean).join(' · '))),
      h('div', { className: 'vl-listrow-end' },
        h(Chip, { tone: SOURCE_TONE[p.source] || 'neutral' }, p.sourceLabel || 'Direct'),
        p.removed ? null : mode === 'before'
          ? h(Button, { variant: 'destructive', small: true }, 'Remove')
          : h('div', { className: 'vl-mark', role: 'group', 'aria-label': 'Attendance for ' + p.name },
              h('button', { type: 'button', className: 'is-attended', 'aria-pressed': p.mark === 'attended' ? 'true' : 'false' }, 'Attended'),
              h('button', { type: 'button', className: 'is-noshow', 'aria-pressed': p.mark === 'no_show' ? 'true' : 'false' }, 'No-show'))));
  }

  function NextSteps(p) {
    return h('div', { className: 'vl-next' }, (p.items || []).map(function (it, i) {
      return h('a', { key: i, href: it.href || '#' },
        it.scene ? h('span', { className: 'vl-next-thumb' }, h(PhotoArt, { scene: it.scene, alt: '' })) : h('span', { className: 'vl-avatar', style: { width: 44, height: 44, background: 'var(--lime)' } }, h(Icon, { name: it.icon || 'share' })),
        h('span', { className: 'vl-next-text' }, h('span', { className: 'vl-next-title' }, it.title), it.meta ? h('span', { className: 'vl-next-meta' }, it.meta) : null),
        h(Icon, { name: 'chevron' }));
    }));
  }

  function PlanCard(p) {
    return h('a', { className: cx('vl-plan', p.past && 'is-past'), href: p.href || '#' },
      h('span', { className: 'vl-plan-thumb' }, h(PhotoArt, { scene: p.scene, alt: '' })),
      h('span', { className: 'vl-plan-main' },
        h('span', { className: 'vl-plan-title' }, p.title),
        h('span', { className: 'vl-plan-meta' }, [p.date, p.place].filter(Boolean).join(' · ')),
        h('span', { className: 'vl-plan-foot' },
          h(AvatarStack, { people: p.members || [], size: 26, max: 3, total: p.memberTotal, label: false }),
          p.removed ? h(Chip, { tone: 'danger' }, 'Removed by host') : p.past ? h(Chip, null, p.attended === false ? 'No-show' : 'Went') : h('span', { className: 'vl-ref-code', style: { fontSize: 13, letterSpacing: 1 } }, p.code))));
  }

  function Banner(p) {
    var tone = p.tone || 'info';
    var icon = p.icon || (tone === 'offline' ? 'offline' : tone === 'error' ? 'alert' : 'info');
    return h('div', { className: cx('vl-banner', tone !== 'info' && 'vl-banner-' + tone), role: tone === 'error' ? 'alert' : 'status' },
      h(Icon, { name: icon }),
      h('div', { className: 'vl-banner-body' }, p.title ? h('strong', null, p.title) : null, p.children),
      p.action || null);
  }

  function Toast(p) {
    return h('div', { className: 'vl-toast', role: 'status' }, h(Icon, { name: p.icon || 'check' }), p.children);
  }

  function ConfirmDialog(p) {
    return h('div', { className: 'vl-dialog-scrim' },
      h('div', { className: 'vl-dialog', role: 'dialog', 'aria-modal': 'true', 'aria-labelledby': 'dlg-title' },
        h('h2', { id: 'dlg-title' }, p.title),
        h('p', null, p.body),
        h('div', { className: 'vl-dialog-actions' },
          h(Button, { variant: 'quiet' }, p.cancel || 'Cancel'),
          h(Button, { variant: p.destructive ? 'danger' : 'primary' }, p.confirm || 'Confirm'))));
  }

  function BottomSheet(p) {
    return h('div', { className: 'vl-sheet', role: 'dialog', 'aria-label': p.label },
      h('span', { className: 'vl-sheet-grip', 'aria-hidden': 'true' }), p.children);
  }

  function EmptyState(p) {
    return h('div', { className: 'vl-empty' },
      h('span', { className: 'vl-empty-mark' }, h(Icon, { name: p.icon || 'sparkle' })),
      h('h3', null, p.title), p.body ? h('p', null, p.body) : null, p.action || null);
  }

  function Skeleton(p) {
    var v = p.variant || 'card';
    if (v === 'text') return h('div', { className: 'vl-skel', style: { height: 14, width: p.width || '70%' } });
    if (v === 'row') return h('div', { className: 'vl-listrow', 'aria-hidden': 'true' },
      h('div', { className: 'vl-skel', style: { width: 40, height: 40, borderRadius: '50%' } }),
      h('div', { style: { flex: 1, display: 'flex', flexDirection: 'column', gap: 8 } }, h('div', { className: 'vl-skel', style: { height: 14, width: '55%' } }), h('div', { className: 'vl-skel', style: { height: 12, width: '35%' } })));
    return h('div', { className: 'vl-activity', 'aria-busy': 'true', 'aria-label': 'Loading' },
      h('div', { className: 'vl-skel', style: { aspectRatio: '16 / 10', borderRadius: 0 } }),
      h('div', { className: 'vl-activity-body' },
        h('div', { className: 'vl-skel', style: { height: 26, width: '75%' } }),
        h('div', { className: 'vl-skel', style: { height: 14, width: '60%' } }),
        h('div', { className: 'vl-skel', style: { height: 14, width: '45%' } }),
        h('div', { className: 'vl-skel', style: { height: 52, borderRadius: 999, marginTop: 8 } })));
  }

  function AppHeader(p) {
    var role = p.role || 'booker';
    var links = role === 'host' ? ['My activities', 'Create activity'] : ['Communities', 'My plans'];
    return h('header', { className: 'vl-header' },
      h('a', { className: 'vl-wordmark', href: '#' }, 'velio'),
      p.compact ? null : h('nav', { className: 'vl-header-nav', 'aria-label': 'Main' }, links.map(function (l) {
        return h('a', { key: l, href: '#', 'aria-current': l === p.current ? 'page' : undefined }, l);
      })),
      h('div', { className: 'vl-header-end' },
        p.signedIn === false ? h(Button, { variant: 'secondary', small: true }, 'Continue') :
          h(Fragment, null,
            h(Segmented, { label: 'Role', value: role === 'host' ? 'Host' : 'Booker', options: ['Booker', 'Host'] }),
            h(Avatar, { name: p.user || 'Tunde Adeyemi', size: 36 }))));
  }

  function AppBar(p) {
    return h('div', { className: 'vl-appbar' },
      p.back === false ? h('span', { style: { width: 44 } }) : h('button', { className: 'vl-iconbtn', type: 'button', 'aria-label': 'Back' }, h(Icon, { name: 'back' })),
      h('span', { className: 'vl-appbar-title' }, p.title),
      p.end || h('span', { style: { width: 44 } }));
  }

  // Representative map art. Production maps are Google Maps; this stands in on the canvas.
  function MapArt(p) {
    var v = p.variant || 'lake';
    return h('svg', { className: 'vl-map-art', viewBox: '0 0 400 225', preserveAspectRatio: 'xMidYMid slice', 'aria-hidden': 'true' },
      h('rect', { width: 400, height: 225, style: { fill: 'var(--map-land)' } }),
      v === 'coast' ? h('path', { d: 'M260 0 C250 60 290 110 270 160 C255 200 290 225 300 225 L400 225 L400 0Z', style: { fill: 'var(--map-water)' } })
        : h('path', { d: 'M40 150 C30 110 80 90 120 100 C160 108 170 140 150 170 C130 200 60 200 40 150Z', style: { fill: 'var(--map-water)' } }),
      h('path', { d: 'M280 20 C320 10 360 40 350 70 C340 100 290 95 275 70 C265 50 262 26 280 20Z', style: { fill: 'var(--map-park)' } }),
      h('path', { d: 'M0 60 L400 40', style: { stroke: 'var(--map-road)', strokeWidth: 7, fill: 'none' } }),
      h('path', { d: 'M180 0 C190 80 200 140 240 225', style: { stroke: 'var(--map-road)', strokeWidth: 9, fill: 'none' } }),
      h('path', { d: 'M0 190 C120 170 220 180 400 150', style: { stroke: 'var(--map-road)', strokeWidth: 5, fill: 'none' } }),
      h('path', { d: 'M90 0 L120 225 M300 225 L330 120 L400 110', style: { stroke: 'var(--map-road)', strokeWidth: 3, fill: 'none' } }));
  }
  function Pin() {
    return h('svg', { className: 'vl-map-pin', viewBox: '0 0 36 46', 'aria-hidden': 'true', style: { left: '50%', top: '52%' } },
      h('path', { d: 'M18 45s15-14.5 15-27A15 15 0 0 0 3 18c0 12.5 15 27 15 27z', style: { fill: 'var(--forest)' } }),
      h('circle', { cx: 18, cy: 18, r: 6.5, style: { fill: 'var(--lime)' } }));
  }
  function MapView(p) {
    var state = p.state || 'static';
    var label = p.label || 'Map of ' + (p.venue || 'the activity location');
    return h('div', { className: 'vl-map', role: 'img', 'aria-label': label, style: p.ratio ? { aspectRatio: p.ratio } : null },
      state === 'failed' || state === 'offline' || state === 'loading' ? null : h(MapArt, { variant: p.art }),
      state === 'static' || state === 'interactive' || state === 'dragging' ? h(Pin) : null,
      state === 'interactive' || state === 'dragging' ? h('div', { className: 'vl-map-controls' },
        h('button', { className: 'vl-iconbtn', type: 'button', 'aria-label': 'Zoom in' }, h(Icon, { name: 'plus' })),
        h('button', { className: 'vl-iconbtn', type: 'button', 'aria-label': 'Zoom out' }, h(Icon, { name: 'minus' }))) : null,
      state === 'static' && p.tapHint ? h('span', { className: 'vl-map-hint' }, h(Chip, { tone: 'outline', icon: 'map' }, 'Tap to explore')) : null,
      state === 'dragging' ? h('span', { className: 'vl-map-hint' }, h(Chip, { tone: 'forest' }, 'Drag the map to place the pin')) : null,
      state === 'loading' ? h('div', { className: 'vl-skel', style: { position: 'absolute', inset: 0, borderRadius: 0 } }) : null,
      state === 'failed' ? h('div', { className: 'vl-map-placeholder' }, h(Icon, { name: 'map' }), h('span', null, 'The map didn’t load. The address below still works.')) : null,
      state === 'offline' ? h('div', { className: 'vl-map-placeholder' }, h(Icon, { name: 'offline' }), h('span', null, 'Map unavailable offline')) : null,
      state === 'failed' || state === 'offline' || state === 'loading' ? null : h('span', { className: 'vl-map-attrib' }, 'Google'),
      p.children);
  }

  function LocationBlock(p) {
    return h('section', { className: 'vl-location', 'aria-label': 'Location' },
      p.title === false ? null : h('h3', { style: { margin: 0, font: '700 17px/24px var(--font-body)' } }, p.title || 'Where'),
      p.map === false ? null : h(MapView, { state: p.mapState || 'static', venue: p.venue, art: p.art, tapHint: p.tapHint, ratio: p.ratio }),
      h('div', { className: 'vl-location-text' }, h(Icon, { name: 'pin' }),
        h('span', null, h('span', { className: 'vl-location-venue' }, p.venue), h('span', { className: 'vl-location-address' }, p.address))),
      p.meetingPoint ? h('div', { className: 'vl-meeting' }, h(Icon, { name: 'flag' }), h('span', null, h('strong', null, 'Meeting point: '), p.meetingPoint)) : null,
      h('div', { className: 'vl-location-actions' },
        h(Button, { variant: 'secondary', small: true, icon: 'directions', href: '#' }, 'Get directions'),
        p.copy ? h(Button, { variant: 'quiet', small: true, icon: 'copy' }, 'Copy address') : null));
  }

  function LocationPicker(p) {
    var state = p.state || 'empty';
    var results = p.results || [
      { name: 'Lake Naivasha Boat Club', sub: 'Moi South Lake Rd, Naivasha, Kenya' },
      { name: 'Lake Naivasha Resort', sub: 'Moi South Lake Rd, Naivasha, Kenya' },
      { name: 'Crescent Island Jetty', sub: 'Naivasha, Kenya' }
    ];
    return h('div', { className: 'vl-picker' },
      h(TextField, { label: 'Location', search: true, value: state === 'empty' ? '' : (p.query || 'Lake Naivasha'), placeholder: 'Search for a place or address', id: 'loc-search',
        error: state === 'noresults' ? 'No places match “' + (p.query || 'Naivasa jety') + '”. Check the spelling, or drop a pin on the map.' : state === 'unavailable' ? 'Place search isn’t available right now. Drop a pin on the map instead.' : null }),
      state === 'results' ? h('div', { className: 'vl-pickres', role: 'listbox', 'aria-label': 'Places' },
        results.map(function (r, i) {
          return h('button', { key: i, type: 'button', role: 'option', 'aria-selected': i === 0 ? 'true' : 'false' }, h(Icon, { name: 'pin' }),
            h('span', null, h('strong', null, r.name), h('span', { className: 'vl-pickres-sub' }, r.sub)));
        }),
        h('div', { className: 'vl-pickres-foot' }, 'Search by Google')) : null,
      state === 'empty' || state === 'results' ? null : h(MapView, { state: state === 'unavailable' ? 'failed' : 'dragging', venue: p.venue, ratio: '16 / 10' }),
      state === 'pinned' || state === 'noresults' ? h('div', { style: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 12 } },
        h(TextField, { label: 'Venue name', value: state === 'pinned' ? 'Lake Naivasha Boat Club' : '', id: 'loc-venue', help: 'What guests will look for when they arrive' }),
        h(TextField, { label: 'Address', value: state === 'pinned' ? 'Moi South Lake Rd, Naivasha, Kenya' : '', id: 'loc-address' })) : null,
      state === 'pinned' ? h(TextField, { label: 'Meeting point (optional)', id: 'loc-meet', value: 'Meet at the blue gate by the jetty', maxLength: 140, count: 34 }) : null,
      h('p', { className: 'vl-public-note', style: { margin: 0 } }, h(Icon, { name: 'info' }), 'The pin, address and meeting point are public. Anyone who sees this activity can see exactly where it is. They lock once someone books.'));
  }

  function CommunityMap(p) {
    var items = p.items || [
      { x: 30, y: 42, label: '6 left', title: 'Sunset Kayaking' },
      { x: 58, y: 30, label: '3 left' },
      { x: 72, y: 64, cluster: 3 },
      { x: 44, y: 72, label: '9 left' }
    ];
    var sel = p.selected;
    return h('div', { className: 'vl-map', style: { aspectRatio: p.ratio || '16 / 10' }, role: 'region', 'aria-label': 'Map of upcoming activities' },
      h(MapArt, { variant: p.art }),
      items.map(function (it, i) {
        return h('button', { key: i, type: 'button', className: cx('vl-map-marker', it.cluster && 'is-cluster', sel === i && 'is-selected'), style: { left: it.x + '%', top: it.y + '%' },
          'aria-label': it.cluster ? it.cluster + ' activities here' : (it.title || 'Activity') + ', ' + it.label },
          it.cluster ? String(it.cluster) : it.label);
      }),
      h('div', { className: 'vl-map-controls' },
        h('button', { className: 'vl-iconbtn', type: 'button', 'aria-label': 'Zoom in' }, h(Icon, { name: 'plus' })),
        h('button', { className: 'vl-iconbtn', type: 'button', 'aria-label': 'Zoom out' }, h(Icon, { name: 'minus' }))),
      sel != null && p.card ? h('div', { className: 'vl-map-card' }, p.card) : h('span', { className: 'vl-map-attrib' }, 'Google'));
  }

  var api = { Icon: Icon, Button: Button, SpotsBadge: SpotsBadge, LivePill: LivePill, Avatar: Avatar, AvatarStack: AvatarStack, Chip: Chip, TextField: TextField, Segmented: Segmented,
    ActivityCard: ActivityCard, DetailRows: DetailRows, BookingRef: BookingRef, MemberRow: MemberRow, AttendanceRow: AttendanceRow, NextSteps: NextSteps, PlanCard: PlanCard,
    Banner: Banner, Toast: Toast, ConfirmDialog: ConfirmDialog, BottomSheet: BottomSheet, EmptyState: EmptyState, Skeleton: Skeleton, AppHeader: AppHeader, AppBar: AppBar,
    MapView: MapView, LocationBlock: LocationBlock, LocationPicker: LocationPicker, CommunityMap: CommunityMap, PhotoArt: PhotoArt, avatarIndex: avatarIndex };
  window.Velio = Object.assign(window.Velio || {}, api);
})();
