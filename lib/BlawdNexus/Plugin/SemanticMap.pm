package BlawdNexus::Plugin::SemanticMap;
use v5.40;
use experimental 'class';
use URI::Escape qw(uri_escape);

class BlawdNexus::Plugin::SemanticMap :isa(BlawdNexus::Plugin) {
    field $analyzer :param;
    field $title :param = undef;
    field $max_nodes :param = undef;
    field $max_depth :param = undef;
    field $min_similarity :param = undef;
    field $wrapper_class :param = undef;
    field $include_script :param = undef;
    field $link_baseurl :param = undef;
    field $map_height :param = undef;
    field $map_width :param = undef;
    
    ADJUST {
        # Initialize defaults from options if not directly provided
        $title //= $self->get_option('title', 'Knowledge Network');
        $max_nodes //= $self->get_option('max_nodes', 15);
        $max_depth //= $self->get_option('max_depth', 2);
        $min_similarity //= $self->get_option('min_similarity', 0.3);
        $wrapper_class //= $self->get_option('wrapper_class', 'semantic-map');
        $include_script //= $self->get_option('include_script', 1);
        $link_baseurl //= $self->get_option('link_baseurl', '/');
        $map_height //= $self->get_option('map_height', 400);
        $map_width //= $self->get_option('map_width', '100%');
    }
    
    method initialize($nexus) {
        # Get the analyzer from the Nexus if not provided
        unless ($analyzer) {
            for my $a (@{$nexus->analyzers}) {
                if ($a->can('discover_connections')) {
                    $analyzer = $a;
                    last;
                }
            }
            
            unless ($analyzer) {
                $self->log("No suitable semantic analyzer found. Plugin disabled.");
                $self->disable;
                return 0;
            }
        }
        
        $self->log("Initialized with analyzer: " . ref($analyzer));
        return 1;
    }
    
    method process($content, $context) {
        # Skip processing if disabled
        return $content unless $self->enabled;
        
        my $entry = $context->{entry};
        return $content unless $entry;
        
        # Generate the knowledge map
        my $map_html = $self->generate_map($entry);
        return $content unless $map_html;
        
        # Return the content with the map appended
        return $content . $map_html;
    }
    
    method generate_map($entry) {
        # Get connections data from the analyzer
        my $connections = $analyzer->discover_connections(
            $entry, 
            $max_depth, 
            $min_similarity
        );
        
        # Skip if no connections found
        return unless $connections && %$connections;
        
        # Convert connections to nodes and links for visualization
        my (@nodes, @links, %seen_nodes);
        
        # Add the central node (current entry)
        push @nodes, {
            id => $entry->filename,
            name => $entry->title,
            group => 1, # central node
            url => $link_baseurl . $entry->filename_base . '.html'
        };
        $seen_nodes{$entry->filename} = 1;
        
        # Process connections
        my $node_count = 1;
        for my $target_filename (sort { 
                $connections->{$b}{similarity} <=> $connections->{$a}{similarity} 
            } keys %$connections) {
            
            last if $node_count >= $max_nodes;
            
            my $connection = $connections->{$target_filename};
            my $target_entry = $connection->{entry};
            
            # Add target node if not already added
            unless ($seen_nodes{$target_filename}) {
                push @nodes, {
                    id => $target_filename,
                    name => $target_entry->title,
                    group => 2, # direct connection
                    url => $link_baseurl . $target_entry->filename_base . '.html'
                };
                $seen_nodes{$target_filename} = 1;
                $node_count++;
            }
            
            # Add direct link
            push @links, {
                source => $entry->filename,
                target => $target_filename,
                value => int($connection->{similarity} * 10), # scale for visualization
                type => 'direct'
            };
            
            # Add path nodes and links if there's an indirect path
            if (@{$connection->{path}}) {
                my $prev_node = $entry->filename;
                for my $path_entry (@{$connection->{path}}) {
                    my $path_filename = $path_entry->filename;
                    
                    # Skip if this exceeds our max nodes
                    last if $node_count >= $max_nodes && !$seen_nodes{$path_filename};
                    
                    # Add path node if not already added
                    unless ($seen_nodes{$path_filename}) {
                        push @nodes, {
                            id => $path_filename,
                            name => $path_entry->title,
                            group => 3, # intermediate node
                            url => $link_baseurl . $path_entry->filename_base . '.html'
                        };
                        $seen_nodes{$path_filename} = 1;
                        $node_count++;
                    }
                    
                    # Add link in the path
                    push @links, {
                        source => $prev_node,
                        target => $path_filename,
                        value => int($connection->{similarity} * 8), # slightly weaker than direct
                        type => 'path'
                    };
                    
                    $prev_node = $path_filename;
                }
                
                # Add final link to target if not already the last node in path
                if ($prev_node ne $target_filename) {
                    push @links, {
                        source => $prev_node,
                        target => $target_filename,
                        value => int($connection->{similarity} * 8),
                        type => 'path'
                    };
                }
            }
        }
        
        # Generate the HTML for the map visualization
        my $node_json = $self->_json_encode(\@nodes);
        my $link_json = $self->_json_encode(\@links);
        
        my $map_html = "<div class='$wrapper_class'>\n";
        $map_html .= "<h3>$title</h3>\n";
        $map_html .= "<div id='knowledge-map' style='width: $map_width; height: ${map_height}px;'></div>\n";
        
        if ($include_script) {
            $map_html .= <<SCRIPT;
<script>
document.addEventListener('DOMContentLoaded', function() {
    // D3.js force-directed graph
    const nodes = $node_json;
    const links = $link_json;
    
    const width = document.getElementById('knowledge-map').clientWidth;
    const height = $map_height;
    
    const svg = d3.select('#knowledge-map')
        .append('svg')
        .attr('width', width)
        .attr('height', height);
    
    // Define arrow markers for links
    svg.append('defs').selectAll('marker')
        .data(['direct', 'path'])
        .enter().append('marker')
        .attr('id', d => \`arrow-\${d}\`)
        .attr('viewBox', '0 -5 10 10')
        .attr('refX', 15)
        .attr('refY', -0.5)
        .attr('markerWidth', 6)
        .attr('markerHeight', 6)
        .attr('orient', 'auto')
        .append('path')
        .attr('fill', d => d === 'direct' ? '#000' : '#666')
        .attr('d', 'M0,-5L10,0L0,5');
    
    // Create the force simulation
    const simulation = d3.forceSimulation(nodes)
        .force('link', d3.forceLink(links).id(d => d.id).distance(d => 100 / d.value))
        .force('charge', d3.forceManyBody().strength(-120))
        .force('center', d3.forceCenter(width / 2, height / 2))
        .force('collision', d3.forceCollide().radius(40));
    
    // Create the links
    const link = svg.append('g')
        .selectAll('line')
        .data(links)
        .enter().append('line')
        .attr('stroke-width', d => Math.sqrt(d.value))
        .attr('stroke', d => d.type === 'direct' ? '#000' : '#666')
        .attr('marker-end', d => \`url(#arrow-\${d.type})\`);
    
    // Create the nodes
    const node = svg.append('g')
        .selectAll('g')
        .data(nodes)
        .enter().append('g');
    
    // Node circles
    node.append('circle')
        .attr('r', d => d.group === 1 ? 12 : (d.group === 2 ? 10 : 8))
        .attr('fill', d => d.group === 1 ? '#ff7f0e' : (d.group === 2 ? '#1f77b4' : '#2ca02c'));
    
    // Node labels
    node.append('text')
        .attr('x', 0)
        .attr('y', -15)
        .attr('text-anchor', 'middle')
        .text(d => d.name)
        .attr('font-size', '10px')
        .attr('pointer-events', 'none')
        .attr('stroke', 'white')
        .attr('stroke-width', 0.5)
        .attr('paint-order', 'stroke');
    
    // Make nodes clickable
    node.on('click', function(event, d) {
        window.location.href = d.url;
    }).style('cursor', 'pointer');
    
    // Update positions on simulation tick
    simulation.on('tick', () => {
        link
            .attr('x1', d => d.source.x)
            .attr('y1', d => d.source.y)
            .attr('x2', d => d.target.x)
            .attr('y2', d => d.target.y);
            
        node.attr('transform', d => \`translate(\${d.x},\${d.y})\`);
    });
    
    // Add zoom capabilities
    const zoom = d3.zoom()
        .on('zoom', (event) => {
            svg.selectAll('g').attr('transform', event.transform);
        });
        
    svg.call(zoom);
});
</script>
SCRIPT
        }
        
        $map_html .= "</div>\n";
        
        return $map_html;
    }
    
    method _json_encode($data) {
        # Simple JSON encoding for the visualization data
        if (eval { require JSON::PP; 1 }) {
            return JSON::PP->new->utf8->encode($data);
        }
        
        # Fallback to manual JSON generation for simple structures
        if (ref $data eq 'ARRAY') {
            my @json_parts;
            for my $item (@$data) {
                push @json_parts, $self->_json_encode($item);
            }
            return '[' . join(',', @json_parts) . ']';
        }
        elsif (ref $data eq 'HASH') {
            my @json_parts;
            for my $key (sort keys %$data) {
                my $value = $data->{$key};
                my $json_key = $self->_json_encode_string($key);
                my $json_value = ref $value ? $self->_json_encode($value) : $self->_json_encode_value($value);
                push @json_parts, "$json_key:$json_value";
            }
            return '{' . join(',', @json_parts) . '}';
        }
        else {
            return $self->_json_encode_value($data);
        }
    }
    
    method _json_encode_string($str) {
        $str =~ s/\\/\\\\/g;   # Escape backslashes
        $str =~ s/"/\\"/g;     # Escape double quotes
        $str =~ s/\n/\\n/g;    # Escape newlines
        $str =~ s/\r/\\r/g;    # Escape carriage returns
        $str =~ s/\t/\\t/g;    # Escape tabs
        return qq("$str");
    }
    
    method _json_encode_value($value) {
        return 'null' unless defined $value;
        return $value =~ /^-?\d+(\.\d+)?$/ ? $value : $self->_json_encode_string($value);
    }
}

1;