// Collapsible Sidebar Menu - State Persistence
// Implements localStorage-based persistence for sidebar collapse/expand state

(function() {
    'use strict';

    // Storage key for sidebar state
    var STORAGE_KEY = 'sidebar-collapse-state';

    // Wait for DOM to be ready
    function ready(fn) {
        if (document.readyState !== 'loading') {
            fn();
        } else {
            document.addEventListener('DOMContentLoaded', fn);
        }
    }

    // Get stored state from localStorage
    function getStoredState() {
        try {
            var stored = localStorage.getItem(STORAGE_KEY);
            return stored ? JSON.parse(stored) : {};
        } catch (e) {
            console.warn('Failed to read sidebar state from localStorage:', e);
            return {};
        }
    }

    // Save state to localStorage
    function saveState(state) {
        try {
            localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
        } catch (e) {
            console.warn('Failed to save sidebar state to localStorage:', e);
        }
    }

    // Get a unique identifier for a menu item based on its href
    function getItemId(element) {
        var link = element.querySelector('a.sidebar-item');
        if (link && link.getAttribute('href')) {
            return link.getAttribute('href');
        }
        // Fallback to text content if no href
        if (link) {
            return link.textContent.trim();
        }
        return null;
    }

    // Initialize sidebar collapse functionality
    function initSidebarCollapse() {
        var state = getStoredState();
        var tocElement = document.querySelector('.toc');
        
        if (!tocElement) {
            return;
        }

        // Find all list items with children (those with expand-stub)
        var itemsWithChildren = tocElement.querySelectorAll('li > .expand-stub');
        
        itemsWithChildren.forEach(function(expandStub) {
            var parentLi = expandStub.parentElement;
            var itemId = getItemId(parentLi);
            
            if (!itemId) {
                return;
            }

            // Restore state from localStorage
            // By default, items are collapsed (no 'in' class)
            // Only expand if explicitly stored as expanded
            if (state[itemId] === true) {
                parentLi.classList.add('in');
            } else {
                parentLi.classList.remove('in');
            }

            // Add click handler to save state
            expandStub.addEventListener('click', function(e) {
                e.stopPropagation();
                var isExpanded = parentLi.classList.contains('in');
                
                // Toggle the 'in' class (docfx.js may also do this, but we ensure it happens)
                parentLi.classList.toggle('in');
                
                // Update and save state
                var newState = getStoredState();
                newState[itemId] = !isExpanded;
                saveState(newState);
            });

            // Also handle clicks on links without href (section headers)
            var link = parentLi.querySelector('.expand-stub + a:not([href])');
            if (link) {
                link.addEventListener('click', function(e) {
                    e.preventDefault();
                    e.stopPropagation();
                    var isExpanded = parentLi.classList.contains('in');
                    
                    parentLi.classList.toggle('in');
                    
                    var newState = getStoredState();
                    newState[itemId] = !isExpanded;
                    saveState(newState);
                });
            }
        });

        // Auto-expand parent items of the currently active page
        var activeItem = tocElement.querySelector('.sidebar-item.active');
        if (activeItem) {
            var parent = activeItem.closest('li').parentElement.closest('li');
            while (parent && parent.tagName === 'LI') {
                parent.classList.add('in');
                
                // Save this expanded state
                var itemId = getItemId(parent);
                if (itemId) {
                    var newState = getStoredState();
                    newState[itemId] = true;
                    saveState(newState);
                }
                
                parent = parent.parentElement.closest('li');
            }
        }
    }

    // Initialize when DOM is ready
    ready(initSidebarCollapse);
})();
