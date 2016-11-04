'use strict';

class AdvancedSelect extends TapBase {
  start(el) {
    this.config = {
      theme: 'bootstrap',
      templateResult: this.renderTemplate.bind(this)
    };

    super.start(el);

    this.$el.select2(this.config);
    this.$el.on('select2:select', this.handleSelect.bind(this));
  }

  handleSelect(event) {
    let itemsToSelect = [],
        selectedOptions = this.$el.find(':selected[data-children-to-select]');

    for (var i = 0; i < selectedOptions.length; i++) {
      let $option = $(selectedOptions[i]);
      $option.prop('selected', false);
      itemsToSelect = itemsToSelect.concat($option.data('childrenToSelect'));
    }
    if (this.$el.val()) {
      this.$el.val(this.$el.val().concat(itemsToSelect));
    } else {
      this.$el.val(itemsToSelect);
    }
    this.$el.trigger('change');
  }

  renderTemplate(state) {
    if (!state.id) { return state.text; }
    var icon = $(state.element).data('icon');
    if (icon) {
      return $('<i class="glyphicon ' + icon + '"></i> ' + '<span>' + state.element.text + '</span>');
    }
    return state.element.text;
  }
}

window.GOVUKAdmin.Modules.AdvancedSelect = AdvancedSelect;
