export interface GameMetadata {
  externalId?: number;
  slug: string;
  name: string;
  alternateNames: string[];
  description: string;
  thumbnailUrl?: string | null;
  imageUrl?: string | null;
  yearPublished?: number | null;
  minPlayers?: number | null;
  maxPlayers?: number | null;
  playingTime?: number | null;
  minPlayTime?: number | null;
  maxPlayTime?: number | null;
  minAge?: number | null;
}

export interface SessionMember {
  online_at: number;
  display_name?: string;
  avatar?: string | null;
}

export interface Session<TGame = unknown> {
  id: string;
  phase: "waiting_for_players" | "in_progress" | "finished";
  owner_id: string;
  members: Record<string, SessionMember>;
  game: TGame;
}
