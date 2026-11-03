import type * as React from 'react';

export type IconName = 'calendar' | 'pin' | 'price' | 'host' | 'people' | 'directions' | 'check' | 'close' | 'search' | 'share' | 'copy' | 'chevron' | 'back' | 'plus' | 'minus' | 'offline' | 'alert' | 'info' | 'lock' | 'map' | 'list' | 'flag' | 'clock' | 'ticket' | 'refresh' | 'menu' | 'target' | 'phone' | 'sparkle' | 'arrow';
export type Scene = 'lake' | 'savanna' | 'city' | 'coast';
export type MapState = 'static' | 'interactive' | 'dragging' | 'loading' | 'failed' | 'offline';

export interface IconProps { name: IconName; label?: string; className?: string }
export declare function Icon(props: IconProps): React.ReactElement;

export interface ButtonProps { variant?: 'primary' | 'secondary' | 'quiet' | 'destructive' | 'danger'; loading?: boolean; disabled?: boolean; block?: boolean; small?: boolean; icon?: IconName; href?: string; type?: 'button' | 'submit'; id?: string; onClick?: () => void; children?: React.ReactNode }
export declare function Button(props: ButtonProps): React.ReactElement;

export interface SpotsBadgeProps { spots: number; state?: 'live' | 'changed' | 'stale'; label?: string }
export declare function SpotsBadge(props: SpotsBadgeProps): React.ReactElement;

export interface LivePillProps { status: 'live' | 'reconnecting' | 'offline'; minutes?: number }
export declare function LivePill(props: LivePillProps): React.ReactElement;

export interface AvatarProps { name: string; seed?: string; size?: number; plus?: number; decorative?: boolean }
export declare function Avatar(props: AvatarProps): React.ReactElement;

export interface AvatarStackProps { people: string[]; total?: number; max?: number; size?: number; label?: string | false }
export declare function AvatarStack(props: AvatarStackProps): React.ReactElement;

export interface ChipProps { tone?: 'neutral' | 'lime' | 'sky' | 'forest' | 'outline' | 'danger'; icon?: IconName; children?: React.ReactNode }
export declare function Chip(props: ChipProps): React.ReactElement;

export interface TextFieldProps { label?: string; id?: string; value?: string; placeholder?: string; help?: string; error?: string | null; code?: boolean; search?: boolean; multiline?: boolean; maxLength?: number; count?: number; type?: string; inputMode?: string; autoComplete?: string; readOnly?: boolean; disabled?: boolean }
export declare function TextField(props: TextFieldProps): React.ReactElement;

export interface SegmentedProps { label: string; value: string; options: Array<string | { value: string; label: string; icon?: IconName }>; onChange?: (value: string) => void }
export declare function Segmented(props: SegmentedProps): React.ReactElement;

export interface ActivityCardProps { title: string; scene?: Scene; spots?: number; spotsState?: 'live' | 'changed' | 'stale'; date?: string; zone?: string; place?: string; address?: string; price?: string; host?: string; going?: string[]; goingTotal?: number; community?: string; lead?: string; compact?: boolean; children?: React.ReactNode }
export declare function ActivityCard(props: ActivityCardProps): React.ReactElement;

export interface DetailRowsProps { rows: Array<{ icon?: IconName; label?: string; value: React.ReactNode; sub?: string }> }
export declare function DetailRows(props: DetailRowsProps): React.ReactElement;

export interface BookingRefProps { code: string; label?: string }
export declare function BookingRef(props: BookingRefProps): React.ReactElement;

export interface MemberRowProps { name: string; meta?: string; source?: 'direct' | 'vouch' | 'public'; sourceLabel?: string; status?: 'created' | 'opened' | 'claimed'; you?: boolean; removed?: boolean; pending?: boolean }
export declare function MemberRow(props: MemberRowProps): React.ReactElement;

export interface AttendanceRowProps { name: string; bookingRef?: string; time?: string; source?: 'direct' | 'vouch' | 'public'; sourceLabel?: string; mode?: 'before' | 'after'; mark?: 'attended' | 'no_show'; isNew?: boolean; removed?: boolean }
export declare function AttendanceRow(props: AttendanceRowProps): React.ReactElement;

export interface NextStepsProps { items: Array<{ title: string; meta?: string; href?: string; scene?: Scene; icon?: IconName }> }
export declare function NextSteps(props: NextStepsProps): React.ReactElement;

export interface PlanCardProps { title: string; scene?: Scene; date?: string; place?: string; members?: string[]; memberTotal?: number; code?: string; removed?: boolean; past?: boolean; attended?: boolean; href?: string }
export declare function PlanCard(props: PlanCardProps): React.ReactElement;

export interface BannerProps { tone?: 'info' | 'offline' | 'error'; title?: string; icon?: IconName; action?: React.ReactNode; children?: React.ReactNode }
export declare function Banner(props: BannerProps): React.ReactElement;

export interface ToastProps { icon?: IconName; children?: React.ReactNode }
export declare function Toast(props: ToastProps): React.ReactElement;

export interface ConfirmDialogProps { title: string; body: string; confirm?: string; cancel?: string; destructive?: boolean }
export declare function ConfirmDialog(props: ConfirmDialogProps): React.ReactElement;

export interface BottomSheetProps { label: string; children?: React.ReactNode }
export declare function BottomSheet(props: BottomSheetProps): React.ReactElement;

export interface EmptyStateProps { title: string; body?: string; icon?: IconName; action?: React.ReactNode }
export declare function EmptyState(props: EmptyStateProps): React.ReactElement;

export interface SkeletonProps { variant?: 'card' | 'row' | 'text'; width?: string }
export declare function Skeleton(props: SkeletonProps): React.ReactElement;

export interface AppHeaderProps { role?: 'booker' | 'host'; current?: string; user?: string; signedIn?: boolean; compact?: boolean }
export declare function AppHeader(props: AppHeaderProps): React.ReactElement;

export interface AppBarProps { title: string; back?: boolean; end?: React.ReactNode }
export declare function AppBar(props: AppBarProps): React.ReactElement;

export interface MapViewProps { state?: MapState; venue?: string; label?: string; ratio?: string; tapHint?: boolean; art?: 'lake' | 'coast'; children?: React.ReactNode }
export declare function MapView(props: MapViewProps): React.ReactElement;

export interface LocationBlockProps { venue: string; address: string; meetingPoint?: string; mapState?: MapState; title?: string | false; map?: boolean; copy?: boolean; tapHint?: boolean; ratio?: string }
export declare function LocationBlock(props: LocationBlockProps): React.ReactElement;

export interface LocationPickerProps { state?: 'empty' | 'results' | 'pinned' | 'noresults' | 'unavailable'; query?: string; results?: Array<{ name: string; sub: string }>; venue?: string }
export declare function LocationPicker(props: LocationPickerProps): React.ReactElement;

export interface CommunityMapProps { items?: Array<{ x: number; y: number; label?: string; title?: string; cluster?: number }>; selected?: number; card?: React.ReactNode; ratio?: string }
export declare function CommunityMap(props: CommunityMapProps): React.ReactElement;

export interface PhotoArtProps { scene?: Scene; alt?: string }
export declare function PhotoArt(props: PhotoArtProps): React.ReactElement;

declare global { interface Window { Velio: { Icon: typeof Icon; Button: typeof Button; SpotsBadge: typeof SpotsBadge; LivePill: typeof LivePill; Avatar: typeof Avatar; AvatarStack: typeof AvatarStack; Chip: typeof Chip; TextField: typeof TextField; Segmented: typeof Segmented; ActivityCard: typeof ActivityCard; DetailRows: typeof DetailRows; BookingRef: typeof BookingRef; MemberRow: typeof MemberRow; AttendanceRow: typeof AttendanceRow; NextSteps: typeof NextSteps; PlanCard: typeof PlanCard; Banner: typeof Banner; Toast: typeof Toast; ConfirmDialog: typeof ConfirmDialog; BottomSheet: typeof BottomSheet; EmptyState: typeof EmptyState; Skeleton: typeof Skeleton; AppHeader: typeof AppHeader; AppBar: typeof AppBar; MapView: typeof MapView; LocationBlock: typeof LocationBlock; LocationPicker: typeof LocationPicker; CommunityMap: typeof CommunityMap; PhotoArt: typeof PhotoArt; avatarIndex: (seed: string) => number } } }
