<template>
  <div class="container">
    <span>
      <a
        href="https://www.markdownguide.org/cheat-sheet/"
        target="_blank"
        style="padding-left: 6px; padding-bottom: 0px;"
      >Markdown </a>
      {{ descriptionLinkingVerb }} supported.
    </span>
  </div>
</template>

<script>
import marked from 'marked';

export default {
  props: {
    placeholderText: {
      type: String,
      default: 'This field supports Markdown. Try it out!'
    }
  },
  computed: {
    markdown() {
      return marked(this.value || '');
    }
  },
  methods: {
    handleChange(e) {
      this.$emit('change', e.target.value);
    }
  }
}
</script>

<style scoped>
@import "../shared/style.css";
</style>

<style>
.container {
  overflow: auto;
  padding: 5px;
  border-radius: 5px;
}

</style>
