# web/lib/ui/search.rb
class Taginfo < Sinatra::Base

    # The search results page
    get '/search' do
        @title = t.pages.search.results.title
        @breadcrumbs << @title

        @query = params[:q]
        if @query =~ /(.*)=(.*)/
            erb :search_tags
        else
            erb :search
        end
    end

    # Return opensearch description (see www.opensearch.org)
    get '/search/opensearch.xml' do
        content_type :opensearch 
        opensearch = <<END_XML
<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
    <ShortName>Taginfo</ShortName>
    <Description>Find metadata about OpenStreetMap tags</Description>
    <Tags>osm openstreetmap tag tags taginfo</Tags>
    <Contact>admin@openstreetmap.de</Contact>
    <Url type="application/x-suggestions+json" rel="suggestions" template="__URL__/search/suggest?term={searchTerms}"/>
    <Url type="text/html" method="get" template="__URL__/search?q={searchTerms}"/>
    <Url type="application/opensearchdescription+xml" rel="self" template="__URL__/opensearch.xml"/>
    <Image height="16" width="16" type="image/x-icon">__URL__/favicon.ico</Image>
</OpenSearchDescription>
END_XML
        return opensearch.gsub(/__URL__/, base_url)
    end

    # Returns search suggestions as per OpenSearch standard
    get '/search/suggest' do
        query = params[:term]
        format = params[:format]

        sel = @db.select('SELECT * FROM suggestions').
            order_by([:score], 'DESC').
            limit(10)

        if query =~ /^=(.*)/
            value = $1
            res = sel.
                condition_if("value LIKE ? || '%'", value).
                execute().
                map{ |row| row['key'] + '=' + row['value'] }
        elsif query =~ /(.*)=(.*)/
            key = $1
            value = $2
            res = sel.
                condition_if("key LIKE ? || '%'", key).
                condition_if("value LIKE ? || '%'", value).
                execute().
                map{ |row| row['key'] + '=' + row['value'] }
        else
            res = sel.
                condition_if("key LIKE ? || '%'", query).
                condition("value IS NULL").
                execute().
                map{ |row| row['key'] }
        end

        if format == 'simple'
            # simple format is used by the search box on the website itself,
            # it is just a list of suggestions
            return res.to_json + "\n";
        else
            # this is the OpenSearch standard format
            return [
                query, # the query string
                res, # the list of suggestions
                res.map{ |item| '' }, # the standard says this is for descriptions, we don't have any so this is empty
                res.map{ |item| base_url + '/tags/' + item } # the page this search should got to (ignored by FF, Chrome)
            ].to_json + "\n"
        end
    end

end