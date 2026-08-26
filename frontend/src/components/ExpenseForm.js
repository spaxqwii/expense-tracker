import React, { useState } from 'react';

function ExpenseForm({ onAddExpense }) {
  const [formData, setFormData] = useState({
    amount: '',
    category: '',
    description: '',
    date: new Date().toISOString().split('T')[0],
  });

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onAddExpense({ ...formData, amount: parseFloat(formData.amount) });
    setFormData({ amount: '', category: '', description: '', date: new Date().toISOString().split('T')[0] });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="number" name="amount" placeholder="Amount" value={formData.amount} onChange={handleChange} required />
      <input type="text" name="category" placeholder="Category" value={formData.category} onChange={handleChange} required />
      <input type="text" name="description" placeholder="Description" value={formData.description} onChange={handleChange} required />
      <input type="date" name="date" value={formData.date} onChange={handleChange} required />
      <button type="submit">Add Expense</button>
    </form>
  );
}

export default ExpenseForm;
