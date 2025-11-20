require 'open-uri'
require 'json'

# Clear existing data (in correct order due to foreign keys)
Bookmark.destroy_all
List.destroy_all
Movie.destroy_all

puts "🎬 Récupération des films depuis l'API TMDB..."

# Fonction pour récupérer les films d'une URL
def fetch_movies(url, page = 1)
  full_url = "#{url}?page=#{page}"
  JSON.parse(URI.open(full_url).read)
rescue => e
  puts "Erreur lors de la récupération: #{e.message}"
  { 'results' => [] }
end

# Fonction pour récupérer la bande-annonce d'un film
def fetch_trailer_key(movie_id)
  url = "https://tmdb.lewagon.com/movie/#{movie_id}/videos"
  videos_data = JSON.parse(URI.open(url, read_timeout: 10).read)

  # Chercher une bande-annonce (trailer) - priorité: anglais, puis français, puis n'importe quelle langue
  trailer = videos_data['results'].find do |video|
    video['type'] == 'Trailer' && video['site'] == 'YouTube'
  end

  # Si pas de trailer, chercher une teaser
  trailer ||= videos_data['results'].find do |video|
    video['type'] == 'Teaser' && video['site'] == 'YouTube'
  end

  trailer ? trailer['key'] : nil
rescue => e
  nil
end

# Fonction pour créer un film
def create_movie(movie_data, fetch_trailer = true)
  return if movie_data['poster_path'].nil? || movie_data['overview'].blank?

  # Récupérer la bande-annonce pour tous les films
  trailer_key = nil
  if fetch_trailer
    print "🎥"
    trailer_key = fetch_trailer_key(movie_data['id'])
    print trailer_key ? "✓" : "✗"
  end

  Movie.create!(
    title: movie_data['title'],
    overview: movie_data['overview'],
    poster_url: "https://image.tmdb.org/t/p/original#{movie_data['poster_path']}",
    rating: movie_data['vote_average'],
    trailer_key: trailer_key
  )
rescue ActiveRecord::RecordInvalid => e
  puts "  ⚠️  Film ignoré (#{movie_data['title']}): #{e.message}"
end

# Récupérer plusieurs types de films
endpoints = [
  { url: 'https://tmdb.lewagon.com/movie/top_rated', pages: 3, name: 'Top Rated' },
  { url: 'https://tmdb.lewagon.com/movie/popular', pages: 3, name: 'Popular' },
  { url: 'https://tmdb.lewagon.com/movie/now_playing', pages: 2, name: 'Now Playing' },
  { url: 'https://tmdb.lewagon.com/movie/upcoming', pages: 2, name: 'Upcoming' }
]

total_created = 0

endpoints.each do |endpoint|
  puts "\n📽️  Récupération des films: #{endpoint[:name]}"

  endpoint[:pages].times do |page|
    page_num = page + 1
    movies_data = fetch_movies(endpoint[:url], page_num)

    movies_data['results'].each_with_index do |movie_data, index|
      # Récupérer les bandes-annonces pour tous les films
      create_movie(movie_data, true)
      total_created += 1
      print " "
    end

    puts " Page #{page_num} terminée"
  end
end

trailers_count = Movie.where.not(trailer_key: nil).count
puts "\n\n✅ Terminé! #{Movie.count} films créés dans la base de données."
puts "   🎥 #{trailers_count} films ont une bande-annonce disponible"
puts "   (Certains films peuvent avoir été ignorés s'ils existaient déjà ou avaient des données invalides)"
