export interface GameDetails {
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

export interface GameSession {
  id: string;
  phase: string;
}
